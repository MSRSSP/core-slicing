set terminal epslatex color  size 3.8in, 1.5in fontscale 0.66
set output 'cloudsuite.tex'
set grid ytic
set key samplen 3 

#set datafile columnheaders
set datafile separator tab
#set datafile missing nan

box_width=0.17
set boxwidth box_width absolute

### Set up style per plot
num_plot = 3
array colors[3]
array patterns[3]
colors[1]="#FF7F0E"
patterns[1] = 3
colors[2]="#136695"
patterns[2] = 15
colors[3]="#136695"
patterns[3] = 22

set key bottom right opaque height 0.75 width 1.5 box Left reverse
set xtics border in scale 0,0 nomirror rotate by -20 offset -2.5 autojustify
set xtics  norangelimit 
set xtics   ()
set xrange [-0.4:3.8]
set yrange [0:110]
set notitle
set ylabel "Performance vs.\\ native" #offset 1,0
set format y "%.0f\\%%" 
set ytic 25
box_width=box_width+0.02

plot "cloudsuite.dat" skip 1 using 0:(0):xtic(1) with boxes notitle, \
    for [i=1:num_plot] "" using ($0+box_width*(i-num_plot/2)):(column(i+1)) w boxes ti columnhead(i+1) fill pattern patterns[i] lc rgb colors[i] lw 3, \
    for [i=1:num_plot] "" using (($0-1)+box_width*(i-num_plot/2)):(column(i+1)):(column(i+1+num_plot)) w yerrorbars notitle lw 1.5 ps 0 lc rgb "black"
