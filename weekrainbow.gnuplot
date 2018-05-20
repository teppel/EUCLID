reset
set datafile sep ';'

set xdata time
set timefmt "%H:%M"
set xrange ["00:00":"23:59"]
set yrange [0:70]		##yrange MUSS gesetzt werden, da nicht alle wochentage gleich oft in den daten vorhanden sind

set grid
set xtics 0, 60*60*6
#set xtics ("00:00" "00:00", "06:00" "6:00", "12:00" "12:00", "18:00" "18:00")
#set xtics add ("03:33" "03:33", 100)
set format x "%H:%M"
set xtics rotate by -90 nomirror
set xtics font "Courier, 10"
set ytics 1 font ",0"
set ylabel "Wochenzähler"

set cbrange [0:999]
set cbtics 20
set palette maxcolors 4
set palette defined (0 "red", 70 "red", 70 "green", 120 "green", 121 "purple", 180 "purple", 181 "black", 1000 "black")
set colorbox horiz user origin .2,.1 size .8,.01
set cbtics rotate by -90 nomirror
set bars 0			##errorbars werden als vertikale striche benutzt weil es keinen pt gibt der so aussieht: | bars=0->keine querstriche oben&unten an den bars
unset border

pointSizeFactor = 1
psize = 0 #0.25

MesswertDatei = "temp//diarywithweekdays.csv"

set title "_      (" . MesswertDatei . ")" . " woche ->" right

set terminal png size 1200,600 enhanced font "Courier,10"
set output "weekrainbow.png"

set multiplot layout 1,7 margins 0.055,0.99,0.2,0.9 	spacing 0.01,0
set label 1 "MON" at graph 0.05,1.025
plot MesswertDatei u 2:((stringcolumn(13) eq "1") ? $14 : 1/0):(0.35):3 w yerrorbars pt 12 palette pointsize psize*pointSizeFactor lw 2 axes x1y1 notitle "BZ MON"
set format y ""
unset ylabel
unset title
unset colorbox
set label 1 "TUE" at graph 0.05,1.025
plot MesswertDatei u 2:((stringcolumn(13) eq "2") ? $14 : 1/0):(0.35):3 w yerrorbars pt 12 palette pointsize psize*pointSizeFactor lw 2 axes x1y1 notitle "BZ TUE"
set label 1 "WED" at graph 0.05,1.025
plot MesswertDatei u 2:((stringcolumn(13) eq "3") ? $14 : 1/0):(0.35):3 w yerrorbars pt 12 palette pointsize psize*pointSizeFactor lw 2 axes x1y1 notitle "BZ WED"
set label 1 "THU" at graph 0.05,1.025
plot MesswertDatei u 2:((stringcolumn(13) eq "4") ? $14 : 1/0):(0.35):3 w yerrorbars pt 12 palette pointsize psize*pointSizeFactor lw 2 axes x1y1 notitle "BZ THU"
set label 1 "FRI" at graph 0.05,1.025
plot MesswertDatei u 2:((stringcolumn(13) eq "5") ? $14 : 1/0):(0.35):3 w yerrorbars pt 12 palette pointsize psize*pointSizeFactor lw 2 axes x1y1 notitle "BZ FRI"
set label 1 "SAT" at graph 0.05,1.025
plot MesswertDatei u 2:((stringcolumn(13) eq "6") ? $14 : 1/0):(0.35):3 w yerrorbars pt 12 palette pointsize psize*pointSizeFactor lw 2 axes x1y1 notitle "BZ SAT"
set label 1 "SUN" at graph 0.05,1.025
plot MesswertDatei u 2:((stringcolumn(13) eq "0") ? $14 : 1/0):(0.35):3 w yerrorbars pt 12 palette pointsize psize*pointSizeFactor lw 2 axes x1y1 notitle "BZ SUN"
	
unset multiplot
