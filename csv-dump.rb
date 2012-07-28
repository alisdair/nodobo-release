# CSV dump of calls, messages, and presence data.
#
# Denormalise the data for easier analysis in Matlab, R, etc.

require './nodobo'
require 'progressbar'
require 'csv'

# http://weblog.jamisbuck.org/2007/4/6/faking-cursors-in-activerecord
class <<ActiveRecord::Base
  def each(limit=1000)
    rows = find(:all, :conditions => ["id > ?", 0], :limit => limit)
    while rows.any?
      rows.each { |record| yield record }
      GC.start
      rows = find(:all, :conditions => ["id > ?", rows.last.id], :limit => limit)
    end
    self
  end
end

user_numbers = Hash[User.all.map {|u| [u.id, u.number] }]
user_macs    = Hash[User.all.map {|u| [u.id, u.devices.last.mac] }]

STDERR.puts "Dumping calls..."
CSV.open("csv/calls.csv", "w") do |csv|
  csv << ["user", "other", "direction", "duration", "timestamp"]
  pb = ProgressBar.new("Calls", Call.count)
  Call.each do |c|
    pb.inc
    csv << [user_numbers[c.user_id], c.number, c.direction, c.duration, c.call_timestamp]
  end
  pb.finish
end

STDERR.puts "Dumping messages..."
CSV.open("csv/messages.csv", "w") do |csv|
  csv << ["user", "other", "direction", "length", "timestamp"]
  pb = ProgressBar.new("Messages", Message.count)
  Message.each do |m|
    pb.inc
    csv << [user_numbers[m.user_id], m.number, m.direction, m.length, m.message_timestamp]
  end
  pb.finish
end

STDERR.puts "Dumping presences..."
CSV.open("csv/presences.csv", "w") do |csv|
  csv << ["user", "other", "name", "class", "timestamp"]
  pb = ProgressBar.new("Presences", Presence.count)
  Presence.each do |p|
    pb.inc
    csv << [user_macs[p.user_id], p.mac, p.name, p.class, p.timestamp]
  end
  pb.finish
end
