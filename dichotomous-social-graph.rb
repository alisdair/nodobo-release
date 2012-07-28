# Social multigraph with dichotomous edges.
#
# Edges exist for calls, messages, and presence. Rules are:
#
# * Reciprocal call (A called B, and B called A)
# * Reciprocal message
# * Presence on x% of active days for y minutes (x=4/7, y=30)

require './nodobo'
require 'progressbar'

def reciprocal_call(a, b)
  # Ignore missed calls
  ["Incoming", "Outgoing"].all? do |direction|
    Call.count(:conditions => ["user_id = ? AND other_id = ? AND direction = ?", a.id, b.id, direction]) > 0
  end
end

def reciprocal_message(a, b)
  ["Incoming", "Outgoing"].all? do |direction|
    Message.count(:conditions => ["user_id = ? AND other_id = ? AND direction = ?", a.id, b.id, direction]) > 0
  end
end

# Reciprocal call, reciprocal message

rc = Set.new
rm = Set.new
STDERR.puts "Calls/messages: examining all pairs of users"
pbar = ProgressBar.new("User", User.count)
for a in User.all
  pbar.inc
  for b in User.all
    if reciprocal_call(a, b)
      rc << Set.new([a.id, b.id])
    end
    if reciprocal_message(a, b)
      rm << Set.new([a.id, b.id])
    end
  end
end
pbar.finish


# Presence

# This approach is really slow, but I can't think of any easy optimisations.

# Hashes of date -> [user_id array]
# Days where a user detected one or more presences
days_detecting = Hash.new
# Days where a user was detected by someone
days_detected = Hash.new

earliest = Presence.first(:conditions => "timestamp > '2010-09-01 00:00:00'", :order => "timestamp").timestamp.to_date
latest   = Presence.first(:order => "timestamp DESC").timestamp.to_date

STDERR.puts "Presence: finding users detecting/detected from #{earliest} -> #{latest}"
pbar = ProgressBar.new("Days", (earliest..latest).to_a.size)
for day in earliest..latest
  pbar.inc
  days_detecting[day] = Presence.find(:all, :conditions => "timestamp LIKE '#{day}%'", :group => :user_id).map &:user_id
  days_detected[day] = Presence.find(:all, :conditions => "other_id IS NOT NULL AND timestamp LIKE '#{day}%'", :group => :other_id).map &:other_id
end
pbar.finish

# Total days a user detected anyone (user_id -> number)
total_days = Hash.new(0)

# Days where a pair of users detected each other (date -> [set of user_id pair sets])
days_pairs = {}

STDERR.puts "Presence: finding pairs of users for each day"
pbar = ProgressBar.new("Days", days_detecting.keys.size)
for day in days_detecting.keys
  pbar.inc
  days_pairs[day] = Set.new
  
  for user in days_detecting[day]
    total_days[user] += 1
    
    # Count the number of presences detected by user
    ps = Presence.connection.select_rows("SELECT other_id, COUNT(*) FROM presences " +
                                         "WHERE user_id = #{user} AND other_id IS NOT NULL AND timestamp LIKE '#{day}%' " +
                                         "GROUP BY other_id")
    
    for other, count in ps
      days_pairs[day] << Set.new([user, other]) if count.to_i > 30 # Arbitrary: require 30 presences for significant
    end
  end
end
pbar.finish

# Invert the map: for each pair, find the days where presence was detected
pair_days = {}
for day in days_pairs.keys
  for pair in days_pairs[day]
    pair_days[pair] ||= []
    pair_days[pair] << day
  end
end

# Regular presence
rp = Set.new

# Cache the minimum number of days for each user to consider a pair significant

sp = 4.0/7.0 # Four days per week (arbitrary)

user_mindays = Hash[total_days.map {|k,v| [k, (sp * v).floor]}]

# Find the pairs significant to each user
for pair in pair_days.keys
  a, b = pair.to_a
  days = pair_days[pair].size
  mindays = [user_mindays[a], user_mindays[b]].compact.min
  if mindays and days > mindays
    rp << pair
  end
end

# ---

# Calculate betweenness centrality

def centrality(users, contacts)
  # Brandes' algorithm, translated from the pseudo-code in:
  #
  # http://www.cs.ucc.ie/~rb4/resources/Brandes.pdf
  
  centrality = Hash.new(0)
  pbar = ProgressBar.new("Centrality", users.size)
  for source in users
    pbar.inc
    stack = []
    paths = Hash.new{|h, k| h[k] = []}
    sigma = Hash.new(0)
    distance = Hash.new(-1)

    sigma[source] = 1
    distance[source] = 0

    queue = []
    queue.unshift(source)

    until queue.empty?
      v = queue.shift
      stack.push(v)
      for c in contacts[v]
        # use cached user contacts
        w = users.find {|u| u == c }
        # w found for the first time?
        if distance[w] < 0
          queue.unshift(w)
          distance[w] = distance[v] + 1
        end

        # shortest path to w via v?
        if distance[w] == distance[v] + 1
          sigma[w] = sigma[w] + sigma[v]
          paths[w] << v
        end
      end
    end

    delta = Hash.new(0)
    # stack returns vertices in order of non-increasing distance from s
    until stack.empty?
      w = stack.pop
      for v in paths[w]
        delta[v] = delta[v] + sigma[v].to_f/sigma[w] * (1 + delta[w])
      end
      if w != source
        centrality[w] = centrality[w] + delta[w]
      end
    end
  end
  pbar.finish

  return centrality
end

users = User.all
contacts = {}
pbar = ProgressBar.new("Contacts", users.size)
for u in users
  pbar.inc
  contacts[u] = User.find(((rc + rm).select {|p| p.include? u.id}.map {|x| x.to_a }.flatten) - [u.id])
end
pbar.finish

centralities = centrality(users, contacts)

BlueHue = 2/3.0
MaxCentrality = centralities.values.max

def color(c);
  "\"#{BlueHue*c/MaxCentrality}, 0.5, 1.0\""
end


# Output the GraphViz dotfile

header = <<EOF
graph
{
    layout = fdp
    splines = true
    K = 2.0
    start = 1
    
EOF

footer = "}"

def edge(p, color)
  a, b = *p
  "\"#{a}\"--\"#{b}\" [color=#{color}]"
end

File.open("dichotomous-social-graph.dot", "w") do |f|
  f << header
  
  f.puts "# Users (coloured by betweenness centrality)"
  for u in users
    c = centralities[u]
    f.puts "\"#{u.id}\" [fillcolor=#{color(c)}, style=filled, tooltip=\"centrality #{c}\"]"
  end
  
  f.puts "# Reciprocal calls"
  for p in rc
    f.puts edge(p, "blue")
  end
  f.puts
  
  f.puts "# Reciprocal messages"
  for p in rm
    f.puts edge(p, "red")
  end
  
  f.puts "# Reciprocal presence"
  for p in rp
    f.puts edge(p, "green")
  end
  
  f.puts footer
end
