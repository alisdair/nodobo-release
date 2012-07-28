set datafile separator ','
set key autotitle columnheader
set ylabel "Percentage"

set term aqua 5
set title "Hourly (weekend)"
plot for [i = 2:4] "csv/hourly-weekend.csv" using i:xtic(1) with lp

set term aqua 0
set title "Hourly (all)"
plot for [i = 2:4] "csv/hourly-all.csv" using i:xtic(1) with lp

set term aqua 1
set title "Hourly (study)"
plot for [i = 2:4] "csv/hourly-study.csv" using i:xtic(1) with lp

set term aqua 2
set title "Hourly (weekday)"
plot for [i = 2:4] "csv/hourly-weekday.csv" using i:xtic(1) with lp


set style data histogram
set style fill solid border -1
set key samplen 1

set term aqua 3
set title "Daily (all)"
plot newhistogram, "csv/daily-all.csv" using 2:xtic(1), newhistogram, "" using 3:xtic(1), newhistogram, '' using 4:xtic(1)

set term aqua 4
set title "Daily (study)"
plot newhistogram, "csv/daily-study.csv" using 2:xtic(1), newhistogram, "" using 3:xtic(1), newhistogram, '' using 4:xtic(1)
