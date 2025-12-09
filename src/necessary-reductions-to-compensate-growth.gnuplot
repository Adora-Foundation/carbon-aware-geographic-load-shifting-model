set terminal pdf enhanced solid font "Helvetica, 14" size 12cm,6cm # monochrome
set output "necessary-reductions-to-compensate-growth.pdf"


set yrange [0:20]
set logscale y
set grid xtics ytics mxtics mytics

set key right bottom box 
set key title "" 

set title "Years of growth compensated by emission reductions " font "Helvetica,18"
set xlabel "Emmission reduction" font "Helvetica,16"
set ylabel "Number of years" font "Helvetica,16"

sc1=.19
sc2=.22
sc3=.27

plot [0:1] \
-log(1-x)/log(1+sc1) title "low-range (19%)",\
-log(1-x)/log(1+sc2) title "medium-range (22%)",\
-log(1-x)/log(1+sc3) title "upper-range (27%)"

#what I want to show is years gained due to reductions. So if we have 
#(1-red)*(1+sc1)**t=(1+sc1)**(t+dt)
#(1-red)*(1+sc1)**t=(1+sc1)**t*(1+sc1)**dt)
#(1-red)=(1+sc1)**dt)

#.5*(1.22**19)=~=(1.22*15) so what we are after here is 19-15 =4

#.5*(1.22**15)*(1.22**dt)=~=(1.22*15)
#.5*(1.22**dt)=~=1
#1.22**dt = 2 = 1/(1-red)
#dt = log(2)/log(1.22)
