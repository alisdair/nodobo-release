# SMS conversation length vs percentage of conversations.
#
# SMS-Kommunikation: Ethnografische Gattungsanalyse am Beispiel einer Kleingrupp
# Jannis Androutsopoulos / Gurly Schmidt
#
# http://www.mediensprache.net/archiv/pubs/1341.pdf
#
# This paper uses message content to determine which messages are part of a
# conversation. We don't have message content, so we use a maximum time
# between messages to group them.

require './nodobo'
require 'csv'

def zug(gms, window=600)
  conversations = Hash.new {|h,k| h[k] = [] }
  for number, nms in gms
    c = []
    for m in nms
      if c.empty? or m.message_timestamp - c.last.message_timestamp < window
        c << m
      else
        conversations[c.size] << c
        c = [m]
      end
    end
  end
  conversations
end

STDERR.puts "Fetching and grouping messages..."
gms = Message.all.group_by &:number

for window in [120, 180, 300, 600, 1800, 3600]
  STDERR.puts "Counting conversations with window size of #{window} seconds..."
  lz = zug(gms, window)
  lz.delete(1) # Ignore single-message conversations
  lc = Hash[lz.map {|k,v| [k, v.size]}]
  total = lc.values.sum
  CSV.open("csv/conversation-length-#{window}.csv", "w") {|csv| lc.sort.each {|p| csv << [p[0], 100.0*p[1]/total] } }
end
