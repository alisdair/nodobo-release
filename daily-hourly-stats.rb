# Daily and hourly calls, messages, presence. Usage patterns!
#
# Calculated for all data, only data where both users are in the study,
# and hourly results only counting weekdays.

require 'csv'
require './nodobo'

c = ActiveRecord::Base.connection
DayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

def report_daily(data, label)
  CSV.open("csv/daily-#{label}.csv", "w") do |csv|
    csv << ["Day", "Calls", "Messages", "Presences"]
    for day in data[:calls].keys.sort
      csv << [DayNames[day.to_i], (100.0*data[:calls][day])/data[:calls].values.sum,
                    (100.0*data[:messages][day])/data[:messages].values.sum,
                    (100.0*data[:presences][day])/data[:presences].values.sum]
    end
  end
end

# Calls/messages/presences by day
daily = {}
STDERR.puts "Daily calls/messages/presence..."

daily[:calls] = Hash[c.select_rows('SELECT strftime("%w", call_timestamp) AS wday, COUNT(*) FROM calls GROUP BY wday;')]
daily[:messages] = Hash[c.select_rows('SELECT strftime("%w", message_timestamp) AS wday, COUNT(*) FROM messages GROUP BY wday;')]
daily[:presences] = Hash[c.select_rows('SELECT strftime("%w", timestamp) AS wday, COUNT(*) FROM presences GROUP BY wday;')]

report_daily(daily, "all")

# Study calls/messages/presences by day
sdaily = {}
STDERR.puts "Daily calls/messages/presence (both parties in study)..."

sdaily[:calls] = Hash[c.select_rows('SELECT strftime("%w", call_timestamp) AS wday, COUNT(*) FROM calls WHERE other_id IS NOT NULL GROUP BY wday;')]
sdaily[:messages] = Hash[c.select_rows('SELECT strftime("%w", message_timestamp) AS wday, COUNT(*) FROM messages WHERE other_id IS NOT NULL GROUP BY wday;')]
sdaily[:presences] = Hash[c.select_rows('SELECT strftime("%w", timestamp) AS wday, COUNT(*) FROM presences WHERE other_id IS NOT NULL GROUP BY wday;')]

report_daily(sdaily, "study")

# ---

def report_hourly(data, label)
  # Hours in data are two-digit 24-hour strings. This is nicest for graphs:
  hours = ((4..23).to_a + (0..3).to_a).map {|x| "%.2d" % x }
  
  # Sometimes not every hour has data...
  data.values.each {|x| x.default = 0 }
  
  CSV.open("csv/hourly-#{label}.csv", "w") do |csv|
    csv << ["Hour", "Calls", "Messages", "Presences"]
    for hour in hours
      csv << [hour, (100.0*data[:calls][hour])/data[:calls].values.sum,
                    (100.0*data[:messages][hour])/data[:messages].values.sum,
                    (100.0*data[:presences][hour])/data[:presences].values.sum]
    end
  end
end

# Calls/messages/presences by hour
hourly = {}
STDERR.puts "Hourly calls/messages/presence..."

hourly[:calls] = Hash[c.select_rows('SELECT SUBSTR(call_timestamp, 12, 2) AS hour, COUNT(*) FROM calls GROUP BY hour;')]
hourly[:messages] = Hash[c.select_rows('SELECT SUBSTR(message_timestamp, 12, 2) AS hour, COUNT(*) FROM messages GROUP BY hour;')]
hourly[:presences] = Hash[c.select_rows('SELECT SUBSTR(timestamp, 12, 2) AS hour, COUNT(*) FROM presences GROUP BY hour;')]

report_hourly(hourly, "all")

# Study calls/messages/presences by hour
shourly = {}
STDERR.puts "Hourly calls/messages/presence (both parties in study)..."

shourly[:calls] = Hash[c.select_rows('SELECT SUBSTR(call_timestamp, 12, 2) AS hour, COUNT(*) FROM calls WHERE other_id IS NOT NULL GROUP BY hour;')]
shourly[:messages] = Hash[c.select_rows('SELECT SUBSTR(message_timestamp, 12, 2) AS hour, COUNT(*) FROM messages WHERE other_id IS NOT NULL GROUP BY hour;')]
shourly[:presences] = Hash[c.select_rows('SELECT SUBSTR(timestamp, 12, 2) AS hour, COUNT(*) FROM presences WHERE other_id IS NOT NULL GROUP BY hour;')]

report_hourly(shourly, "study")

# Weekday calls/messages/presences by hour
whourly = {}
STDERR.puts "Hourly calls/messages/presence (only weekdays)..."
whourly[:calls] = Hash[c.select_rows('SELECT SUBSTR(call_timestamp, 12, 2) AS hour, COUNT(*) FROM calls WHERE strftime("%w", call_timestamp) != "0" AND strftime("%w", call_timestamp) != "6" GROUP BY hour;')]
whourly[:messages] = Hash[c.select_rows('SELECT SUBSTR(message_timestamp, 12, 2) AS hour, COUNT(*) FROM messages WHERE strftime("%w", message_timestamp) != "0" AND strftime("%w", message_timestamp) != "6"  GROUP BY hour;')]
whourly[:presences] = Hash[c.select_rows('SELECT SUBSTR(timestamp, 12, 2) AS hour, COUNT(*) FROM presences WHERE strftime("%w", timestamp) != "0" AND strftime("%w", timestamp) != "6"  GROUP BY hour;')]


report_hourly(whourly, "weekday")


# Weekend calls/messages/presences by hour
wehourly = {}
STDERR.puts "Hourly calls/messages/presence (only weekends)..."
wehourly[:calls] = Hash[c.select_rows('SELECT SUBSTR(call_timestamp, 12, 2) AS hour, COUNT(*) FROM calls WHERE strftime("%w", call_timestamp) = "0" OR strftime("%w", call_timestamp) = "6" GROUP BY hour;')]
wehourly[:messages] = Hash[c.select_rows('SELECT SUBSTR(message_timestamp, 12, 2) AS hour, COUNT(*) FROM messages WHERE strftime("%w", message_timestamp) = "0" OR strftime("%w", message_timestamp) = "6"  GROUP BY hour;')]
wehourly[:presences] = Hash[c.select_rows('SELECT SUBSTR(timestamp, 12, 2) AS hour, COUNT(*) FROM presences WHERE strftime("%w", timestamp) = "0" OR strftime("%w", timestamp) = "6"  GROUP BY hour;')]


report_hourly(wehourly, "weekend")
