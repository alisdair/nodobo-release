set dataf sep ","
set xlabel "Conversation length"
set ylabel "Percentage of conversations"
set logscale x
set xrange[2:20]

# set term aqua 0
# set title "SMS conversation length (window size 2 minutes)"
# plot "csv/conversation-length-120.csv" with linespoints
# 
# set term aqua 1
# set title "SMS conversation length (window size 5 minutes)"
# plot "csv/conversation-length-300.csv" with linespoints
# 
# set term aqua 2
# set title "SMS conversation length (window size 10 minutes)"
# plot "csv/conversation-length-600.csv" with linespoints
# 
# set term aqua 3
# set title "SMS conversation length (window size 30 minutes)"
# plot "csv/conversation-length-1800.csv" with linespoints
# 
# set term aqua 4
# set title "SMS conversation length (window size 1 hour)"
# plot "csv/conversation-length-3600.csv" with linespoints
# 
# set term aqua 5
# set title "SMS conversation length (as published)"
# plot "csv/conversation-length-published.csv" with linespoints

set term aqua 0
plot "csv/conversation-length-120.csv" title "Nodobo 2 min" with linespoints, "csv/conversation-length-180.csv" title "Nodobo 3 min" with linespoints, "csv/conversation-length-300.csv" title "Nodobo 5 min" with linespoints, "csv/conversation-length-published.csv" title "Androutsopoulos" with linespoints

set term aqua 1 dashed
plot "csv/conversation-length-180.csv" title "Nodobo" with linespoints, "csv/conversation-length-published.csv" title "Androutsopoulos" with linespoints
