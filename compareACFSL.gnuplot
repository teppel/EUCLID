reset

set title Titel

set datafile sep ';'
BZmax = 220
set xrange [0:BZmax]
set yrange [0:BZmax]
set xtics 20
set ytics 20
set xtics rotate by -60

set grid

set terminal png size 500,500 enhanced font "Courier,10"
set output plotDateiName
set size square

set xlabel "accu check"
set ylabel "freestyle libre"

#set palette defined (-20 "black", -10 "red", 0 "green", 10 "red", 20 "black")
#set cbrange [-20:20]

set arrow 5 from 0,0 to BZmax,BZmax nohead
plot MesswertDatei u 1:2 w points lc "black" pt 7 ps 1 notitle
#plot MesswertDatei u 1:2:($1-$2) w points palette pt 7 ps 1 notitle