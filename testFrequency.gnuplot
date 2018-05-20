##DATUM;Anzahl_tägliche_Messungen;AnzahlDoppelMessungen;AnzahlFarOutRangeMessungen
##24.12.2013;6

reset

if (!exists ("Titel")) {
	Titel = "Anzahl Messungen pro Tag"
	}
set title Titel

if (!exists ("plotDateiName")) {
	plotDateiName = "testfrequency.png"
	}

if (!exists ("wertedatei")) {
		wertedatei = "temp/testfrequency.csv"
		print ("wertedatei not set. defaults to:" . wertedatei)
		}
if (!exists ("farOutLO")) {
	farOutLO = 55
	print ("farOutLO not set. defaults to:".farOutLO)
	}
if (!exists ("farOutHI")) {
	farOutHI = 180
	print ("farOutHI not set. defaults to:".farOutHI)
	}


set terminal png size 1200,300 enhanced font "Courier,10"
set output plotDateiName

#Trennzeichen zwischen csv keys ist: ;
set datafile sep ';'

stats wertedatei using 2 prefix "TAGESMESS"

ZeitFormat = '%d.%m.%Y'
set timefmt ZeitFormat
set xdata time
#set xrange ["01.06.2016":]		#das ist nur für die Anzeige. Durchschnitt ist immer komplette Datei!
set grid
set style fill solid noborder

set multiplot layout 1,2
set size 0.7,1
set boxwidth #0.05
plot wertedatei u 1:2 w boxes lc "dark-grey" notitle,\
	wertedatei u 1:3 w boxes lc "red" title "Doppelmessung",\
	TAGESMESS_mean title "Durchschnitt: ".sprintf('%.2f', TAGESMESS_mean+0),\
	wertedatei u 1:($4 > 0 ? $4 : 1/0) w points title "BZ <".farOutLO." oder >".farOutHI pt 7



set size 0.3,1
set origin 0.7,0

unset xdata
set xrange [0:]
set title "Verteilung Messungen/Tag" . " (gesamt:".sprintf('%.0f',TAGESMESS_sum+0).")"
set key above
set xtics 1
set boxwidth 0.4 #0.05 absolute
width=1 	#interval width
#function used to map a value to the intervals
hist(x,width)=width*floor(x/width)
plot wertedatei  u (hist($2,width)):(1.0) smooth freq w boxes lc rgb"dark-gray" notitle #title "Verteilung Messungen/Tag"
