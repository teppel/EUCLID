reset
set datafile sep ';'

set xdata time
set timefmt "%H:%M"
set xrange ["00:00":"23:59"]
set yrange [0:250]

set grid
set xtics 0, 60*60*6
#set xtics ("00:00" "00:00", "06:00" "6:00", "12:00" "12:00", "18:00" "18:00")
#set xtics add ("03:33" "03:33", 100)
set format x "%H:%M"
set xtics rotate by -90 nomirror
set xtics font "Courier, 10"
set ytics 25 font ",0"
set ylabel "BZ [mg/dl]"


pointSizeFactor = 1
psize = 0.2

set title "wochentage 1.1 bis 19.5 2017"

#MesswertDatei = "temp//diarywithweekdays.csv"

set terminal png size 1200,300 enhanced font "Courier,10"
set output plotDateiName #"weekdays.png"

set multiplot layout 1,7 margins 0.075,0.98,0.2,0.9 	spacing 0.01,0
set label 1 "MON" at graph 0.05,0.95
plot MesswertDatei u 2:((stringcolumn(13) eq "1") ? $3 : 1/0) w points pt 12 linecolor "red" pointsize psize*pointSizeFactor lw 2 axes x1y1 notitle "BZ MON"
set format y ""
unset ylabel
unset title
set label 1 "TUE" at graph 0.05,0.95
plot MesswertDatei u 2:((stringcolumn(13) eq "2") ? $3 : 1/0) w points pt 12 linecolor "black" pointsize psize*pointSizeFactor lw 2 axes x1y1 notitle "BZ TUE"
set label 1 "WED" at graph 0.05,0.95
plot MesswertDatei u 2:((stringcolumn(13) eq "3") ? $3 : 1/0) w points pt 12 linecolor "blue" pointsize psize*pointSizeFactor lw 2 axes x1y1 notitle "BZ WED"
set label 1 "THU" at graph 0.05,0.95
plot MesswertDatei u 2:((stringcolumn(13) eq "4") ? $3 : 1/0) w points pt 12 linecolor "green" pointsize psize*pointSizeFactor lw 2 axes x1y1 notitle "BZ THU"
set label 1 "FRI" at graph 0.05,0.95
plot MesswertDatei u 2:((stringcolumn(13) eq "5") ? $3 : 1/0) w points pt 12 linecolor "cyan" pointsize psize*pointSizeFactor lw 2 axes x1y1 notitle "BZ FRI"
set label 1 "SAT" at graph 0.05,0.95
plot MesswertDatei u 2:((stringcolumn(13) eq "6") ? $3 : 1/0) w points pt 12 linecolor "orange" pointsize psize*pointSizeFactor lw 2 axes x1y1 notitle "BZ SAT"
set label 1 "SUN" at graph 0.05,0.95
plot MesswertDatei u 2:((stringcolumn(13) eq "0") ? $3 : 1/0) w points pt 12 linecolor "purple" pointsize psize*pointSizeFactor lw 2 axes x1y1 notitle "BZ SUN"
	
unset multiplot