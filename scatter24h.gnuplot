reset
########################################
#### BZ Tagesverlauf 00:00 bis 24:00 ###
set datafile sep ';'
##stats muss vor 'set xdata time' laufen, weil stats nicht bei zeitformat geht.
#und wechsel zu zeitformat löscht die stats-variablen, darum dieser blödsinn..
stats MesswertDatei using 3 prefix "BZ"
BZ_meanavg = BZ_mean
hba1c = 0.031 *BZ_meanavg + 2.393		## http://www.insulin-dosierung.de/service/hba1c/
BZ_stddeviation = BZ_stddev

set xdata time
set timefmt "%H:%M"
set xrange ["00:00":"23:59"]
set grid
set xtics 60*60
set format x "%H:%M"
set xtics rotate by -60 nomirror
set xtics font "Courier, 10"
set ytics 25
set ylabel "BZ [mg/dl]"
maxBZ=250
set yrange [0:maxBZ]
#set label "03:33" at "03:33",250  center rotate by 90 back	##Kontrollerwecker 3Uhr33
set xtics add ("03:33" "03:33", 100)
set xtics add ("02:22" "02:22", 100)
BZobergrenze = 140
BZuntergrenze = 70

##rug plot 
##	MesswertDatei u 2:3:x2tic(""):y2tic("") # with points ps 0.5
##geht, malt aber iwie auf y-achse bei ~20 einen falschen verwirrenden strich
#set x2tics out scale 3
#set y2tics out scale 3


#Legende
set key bottom left outside horizontal				#Position
set key samplen 2				#Länge der Linie
set key font "Courier,10"	#Font
set key spacing 0.8			#vertikaler Abstand
set key box						#mit Rahmen


if (!exists ("Titel")) {
	Titel = "BZ 24h Verteilung"
	}
set title Titel
unset title

if (!exists ("plotDateiName")) {
	plotDateiName = "24scatter.png"
	}

set terminal png size 1200,300 enhanced font "Courier,10"
set output plotDateiName

#MesswertDatei = "Q//22.12.2016-7.02.2017.csv"

pointSizeFactor = 1	#png=1  pdf=0.2
###styles
	#Style 1 = der BZ Graph
set style line 1 lt 1 linecolor "red" linewidth 1 pointtype 7 pointsize 1.2 * pointSizeFactor
	#Style 2 = BZobergrenze
set style line 2 lt 1 linecolor "purple" linewidth 2 pointtype 2 pointsize 1 * pointSizeFactor
	#Style 3 = BZuntergrenze
set style line 3 lt 1 linecolor "blue" linewidth 2 pointtype 2 pointsize 1 * pointSizeFactor



plot BZobergrenze ls 2 axes x1y1 title "BZ=".BZobergrenze ,\
	BZuntergrenze ls 3 axes x1y1 title "BZ=".BZuntergrenze ,\
	MesswertDatei u 2:($3 > maxBZ ? maxBZ : 1/0) w points pointtype 9 linecolor "purple" pointsize 2*pointSizeFactor axes x1y1 title ">".maxBZ."mg/dl" ,\
	MesswertDatei u 2:3 w points lw 0.1 pointsize 0.9*pointSizeFactor pt 7 linecolor "red" title "BZ accu-check(".MesswertDatei.")" ,\
	MesswertDatei u 2:((stringcolumn(10) eq "X") ? $3 : 1/0) w points pt 12 linecolor "black" pointsize 1.1*pointSizeFactor lw 2 axes x1y1 title "BZ nuechtern" ,\
	BZ_meanavg title "mean avg:".sprintf('%.2f', BZ_mean+0)." (hba1c:".sprintf('%.1f',hba1c) .")" ."stddev:".sprintf('%.1f', BZ_stddeviation)
	
	
