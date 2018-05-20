reset
### parameter http://stackoverflow.com/questions/12328603/how-to-pass-command-line-argument-to-gnuplot ###
## $ gnuplot -e "Titel='Ueberschrift' ; plotDateiName='bla.png'" timegraph.gnuplot

###################################################################################
###################################################################################
## Datum;Uhrzeit;Messwert;Einheit;Temperaturwarnung;Außerhalb Zielbereich;
##  1      2       3        4            5              6                  
## Sonstiges;Vor Mahlzeit;Nach Mahlzeit;Nüchtern;Schlafenszeit;Funktionskontrolle                                                                                                                                                               
##	  7            8           9           10           11             12


extraMesswertDatei = "extraMessungen.csv"			#fremdgemesse Werte (zB Arzt)

BZobergrenze = 140
BZuntergrenze = 70
BZuz1 = 70
BZuz2 = 55

###################################################################################
###################################################################################
plotteZusatz = 0
## default parameters
if (!exists ("fslDatei")) {
	fslDatei = "empty.txt" #"days/FSL_10_12_2016.csv"
	}

if (!exists ("MesswertDatei")) {
	MesswertDatei = "diary.csv" ##ohneEinschwing.csv"							#aus accu-check
	}

if (!exists ("PlotZeitStart")) {
	PlotZeitStart = "5.08.2016;00:00"	## "" -> alles
	}
if (!exists ("PlotZeitEnde")) {
	PlotZeitEnde = "5.08.2016;23:59"
	}


if (!exists ("plotDateiName")) {
	plotDateiName = "output.png"
	if (PlotZeitStart != "")  { plotDateiName = plotDateiName .PlotZeitStart." bis  ".PlotZeitEnde.".png"
	}

if (!exists ("Titel")) {
	Titel = fslDatei . "\n" . MesswertDatei		
	Titel = "BZ " .PlotZeitStart ." bis  ".PlotZeitEnde
	} else {
	Titel = fslDatei . "\n" . MesswertDatei
	}
}

##################################################################################
##Zeitformat accu-check diary.csv: 13.07.2016;21:16	-	neuste Werte stehen oben!
ZeitFormat = '%d.%m.%Y; %H:%M'
set timefmt ZeitFormat
set xdata time
#Trennzeichen zwischen csv keys ist: ;
set datafile sep ';'

#Achsenbeschriftung & Titel
unset xlabel
set ylabel "BZ [mg/dl]"
set ylabel offset 2, 0					#Abstand zum Graph verkleinern
set title Titel font "Courier, 20"

#Grid und Tics
set grid
set xtics rotate by -60 nomirror
set xtics font "Courier, 10"
set xtics 60*60*24						#jeder Tag mit Datum
set xtics offset 0, graph 0.025			#etwas näher an den Graph schieben
set ytics 25							#Schrittweite für BZ auf y-Achse
#set format x "%d.%m.%y\r\n(%a)"			#Zeitformat Beschriftung X-Achse
set format x "%d.%m.%y(%a)"

###experimentel: xtics Schrittweite an geplotteten Zeitraum anpassen
PlotZeitDauer = abs (strptime (ZeitFormat, PlotZeitEnde) - strptime (ZeitFormat, PlotZeitStart))/60/60/24
print "PlotZeitDauer:" , PlotZeitDauer

#0.0 entspricht alles
if (PlotZeitDauer == 0.0) {
	set xtics 60*60*24 *1 ##*7 = woche
}
else {
	if (PlotZeitDauer > 6) {set xtics 60*60*24  *1}
	if (PlotZeitDauer > 10) {set xtics 60*60*24 }
	if (PlotZeitDauer > 30) {set xtics 60*60*24 *1}
	if (PlotZeitDauer > 60) {
		set xtics 60*60*24  *7
		#unset mxtics
		}
	if (PlotZeitDauer > 365) {
		set xtics 60*60*24  *30
		unset mxtics
		}
	

	if (PlotZeitDauer < 2) {
		set xtics 60*60 *1
		#set format x "%d.%m %H:%M\n\r%a"
		set format x "%H:%M"
	}
}

set bmargin 7 	# The units of margins are character heights (or widths)

#set size 1, 1 ###############################################################################################
#Legende
set key bottom left outside horizontal				#Position
#set key at graph 1,-0.4 horizontal 
set key samplen 2				#Länge der Linie
set key font "Courier,10"	#Font
set key spacing 0.8			#vertikaler Abstand
set key box						#mit Rahmen
#unset key

#Anzeigebereich & Zeitraum
unset autoscale
set yrange [0 : 300]			#BZ
if (PlotZeitStart != "") set xrange [PlotZeitStart : PlotZeitEnde]

####Zweite y-Achse: BE & Insulin###
##funktioniert, aber ich trage es nicht mehr ein
if (plotteZusatz==1) {
set y2range [0:30]			#Insulin IE
set y2tics 0, 5
set boxwidth (60*60)*0.3
set y2label "BE und Insulin"
}

###	je nach Terminal (png / pdf) sind die points verschieden gross.
###	das ist ja mal voll scheisse. mit pointSizeFactor wird es hingepfuscht.
pointSizeFactor = 1	#png=1  pdf=0.2

#styles
	#Style 1 = der BZ Graph
set style line 1 lt 1 linecolor "red" linewidth 2 pointtype 7 pointsize 1 * pointSizeFactor
	#Style 2 = BZobergrenze
set style line 2 lt 1 linecolor "purple" linewidth 2 pointtype 2 pointsize 1 * pointSizeFactor
	#Style 3 = BZuntergrenze
set style line 3 lt 1 linecolor "blue" linewidth 2 pointtype 2 pointsize 1 * pointSizeFactor
	#Style 4 = FSL continious
set style line 4 lt 1 linecolor "dark-gray" linewidth 2 pointtype 2 pointsize 1 * pointSizeFactor
	#Style 5 = FSL manual scans
set style line 5 lt 1 linecolor "gray" linewidth 2 pointtype 19 pointsize 2 * pointSizeFactor
	#Style 10 = BZ Graph Alt/alternativ
set style line 10 lt 1 linecolor "green" linewidth 1 pointtype 7 pointsize 1.2 * pointSizeFactor



##Ausgabe png:
#NOTE / TODO: pdf
set terminal png size 1200,500 enhanced font "Courier,15"	#png geht! #1200,600



##Ausgabe pdf:
#pdf: mit 'terminal size' sieht es scheisse aus aber ohne wird die hälfte iwie nicht gemalt.
# muss 'set point size 0.1' sonst sind punkte riesig. ABER: die styles machen konflikt (doppelt)
#darum nun der pointSizeFaktor
#set terminal pdf #size 1900,600	 #enhanced font "Courier,20"

set output plotDateiName

if (plotteZusatz==1) {
plot fslDatei u 1:3 smooth csplines w linespoints ls 4 pointsize 0.5*pointSizeFactor axes x1y1 title "FSL" ,\
	fslDatei u 1:4 w points ls 5 axes x1y1 title "FSL (scans)" ,\
	MesswertDatei u 1:3 w  linespoints ls 1 axes x1y1 title "BZ accu-check",\
	BZobergrenze ls 2 axes x1y1 title "BZ=".BZobergrenze,\
	BZuntergrenze ls 3 axes x1y1 title "BZ=".BZuntergrenze,\
	extraMesswertDatei u 1:3 w points pointtype 2 pointsize 1*pointSizeFactor linecolor "black" axes x1y1 title "BZ Fremdmessung" ,\
	MesswertDatei u 1:((stringcolumn(10) eq "X") ? $3 : 1/0) w points pointtype 3 linewidth 2 linecolor "black" pointsize 2*pointSizeFactor axes x1y1 title "nuechtern" ,\
	MesswertDatei u 1:((stringcolumn(8) eq "X") ? $3 : 1/0) w points pointtype 5 linecolor "blue" pointsize 0.5*pointSizeFactor axes x1y1 title "vor Mahlzeit" ,\
	'zusatz.csv' u 1:3 w points pointtype 5 pointsize 3*pointSizeFactor linecolor "orange" axes x1y2 title "BE" ,\
	'zusatz.csv' u 1:4 w boxes fill solid 0.5 linecolor "green" axes x1y2 title "Bolus IE" ,\
	'zusatz.csv' u 1:5 w points pointtype 13 pointsize 2*pointSizeFactor axes x1y2 title "Basal IE"
}else{
plot fslDatei u 1:3 w linespoints ls 4 pointsize 0.0*pointSizeFactor axes x1y1 title "FSL" ,\
	fslDatei u 1:4 w points ls 5 axes x1y1 title "FSL (scans)" ,\
	MesswertDatei u 1:3 w  linespoints ls 1 axes x1y1 title "BZ accu-check",\
	BZobergrenze ls 2 axes x1y1 title "BZ=".BZobergrenze,\
	BZuntergrenze ls 3 axes x1y1 title "BZ=".BZuntergrenze,\
	extraMesswertDatei u 1:3 w points pointtype 2 pointsize 1*pointSizeFactor linecolor "black" axes x1y1 title "BZ Fremdmessung" ,\
	MesswertDatei u 1:((stringcolumn(10) eq "X") ? $3 : 1/0) w points pointtype 3 linewidth 2 linecolor "black" pointsize 2*pointSizeFactor axes x1y1 title "nuechtern" ,\
	MesswertDatei u 1:((stringcolumn(7) eq "X") ? $3 : 1/0) w points pointtype 8 linewidth 2 linecolor "dark-green" pointsize 1*pointSizeFactor axes x1y1 title "sonstiges (BE++)" ,\
	MesswertDatei u 1:((stringcolumn(8) eq "X") ? $3 : 1/0) w points pointtype 5 linecolor "blue" pointsize 0.5*pointSizeFactor axes x1y1 title "vor Mahlzeit" ,\
	MesswertDatei u 1:($3 < BZuz1 ? 0+5 : 1/0) w points pointtype 11 linecolor "orange" pointsize 1*pointSizeFactor axes x1y1 title "<".BZuz1."mg/dl",\
	MesswertDatei u 1:($3 < BZuz2 ? 0+5 : 1/0) w points pointtype 11 linecolor "red" pointsize 1.5*pointSizeFactor axes x1y1 title "<".BZuz2."mg/dl"
}




#plot MesswertDatei u 1:3 w linespoints ls 1 pointsize pointSizeFactor axes x1y1 title "Blutzucker accu-check",\
#	fslDatei u 1:3 w linespoints ls 4 pointsize 0.5*pointSizeFactor axes x1y1 title "FSL"

########################################						    
########################################
