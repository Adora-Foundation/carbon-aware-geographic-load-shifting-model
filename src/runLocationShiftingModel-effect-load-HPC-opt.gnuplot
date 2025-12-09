set terminal pdf enhanced solid font "Helvetica, 14" size 12cm,10cm # monochrome
set output "runLocationShiftingModel-effect-load-HPC-opt.pdf"
set datafile separator comma

set yrange [0:100]
#set logscale y # 2
#set xtics 4
#set mxtics 4
set grid xtics ytics mxtics mytics

#set key autotitle columnhead
set key right bottom box 
set key title "" 

set title "Emmission reductions versus load" font "Helvetica,18"
set xlabel "Load" font "Helvetica,16"
set ylabel "Emissions reductions (%)" font "Helvetica,16"


set title "Scenario 1" font "Helvetica,18"
plot  \
'runLocationShiftingModel-effect-load-HPC-opt.csv' using ($1):($2) title "Actual" with linespoints lw 2 ps 0.3 pt 5,\
'runLocationShiftingModel-effect-load-HPC-opt.csv' using ($1):($3)  title "Idle power = 0" with linespoints lw 2 ps 0.3 pt 3, \
'runLocationShiftingModel-effect-load-HPC-opt.csv' using ($1):($4)  title "Embodied carbon = 0" with linespoints lw 2 ps 0.3 pt 4, \
'runLocationShiftingModel-effect-load-HPC-opt.csv' using ($1):($5)  title "Idle power = 0, embodied carbon = 0" with linespoints lw 2 ps 0.3 pt 5 