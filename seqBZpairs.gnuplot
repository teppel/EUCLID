reset
## parameter: $ gnuplot -e "Titel='Ueberschrift' ; seqFile='bla.csv'" seqBZpairs.gnuplot

## seqFile = "temp/seqBZpairs.csv"

set terminal png size 800,700 enhanced font "Courier"
set output plotDateiName

if (!exists ("Titel")) {	
	Titel = "Änderung zwischen zwei aufeinanderfolgenden Messungen (" . seqFile . ")"
	}

set title Titel #font "Courier, 20"

maxDT = 6*60
maxDT2 = 2*60
doppelMessDT = 10 #unterhalb dieser zeitdifferenz -> doppelte Messung (zB wenn Wert seltsam erschien oder vor Korrektur)
BZmax = 300

set datafile sep ';'
set palette color
set palette defined (0 "green", doppelMessDT-1 "green", doppelMessDT "black", 1*60 "red",2*60 "red", 4*60 "blue", 6*60 "blue")
set cblabel "Zeitdifferenz dt [min]"
set cbrange [0:6*60]
set cbtics 30
# set colorbox horiz user origin .6,.05 size .2,.04

PUNKTGROESSE = 0.9

set key outside bottom left box horizontal

set arrow 1 from 80,0 to 80,300 nohead
set arrow 2 from 120,0 to 120,300 nohead
set arrow 3 from 0,80 to 300,80 nohead
set arrow 4 from 0,120 to 300,120 nohead
set arrow 4 from 0,120 to 300,120 nohead
set arrow 5 from 0,0 to 300,300 nohead

set size square
set grid
set xtics 20 rotate by -90 nomirror
set ytics 20
set xrange [0:BZmax]
set yrange [0:BZmax]
set xlabel "BZ(t) [mg/dl]"
set ylabel "BZ(t+1) [mg/dl] 'als nächstes gemessenen'"

## nur der plot:
#unset colorbox
#unset key

if (exists ("FSL")) {
#plot seqFile using 1:2:3 with lines lw 0.1 notitle,\
plot seqFile using 1:2:3 with points pointtype 7 ps 0.75*PUNKTGROESSE title "FSL export ~15min"
#plot seqFile using 1:2:3 with points pointtype 7 ps 0.75*PUNKTGROESSE title "FSL export ~15min"
}
else {
plot seqFile using 1:2:3 with points pointtype 6 ps PUNKTGROESSE title ("dt > ".maxDT. " Minuten"),\
	seqFile using ($3 <= maxDT ? $1 : 1/0):($3 <= maxDT ? $2 : 1/0):($3 <= maxDT ? $3 : 1/0) with points palette pointtype 7 ps PUNKTGROESSE notitle ,\
	seqFile using ($3 <= maxDT2 ? $1 : 1/0):($3 <= maxDT2 ? $2 : 1/0):($3 <= maxDT2 ? $3 : 1/0) with points palette pointtype 9 ps PUNKTGROESSE*1.5 title ("dt < ".maxDT2. " Minuten")
}
