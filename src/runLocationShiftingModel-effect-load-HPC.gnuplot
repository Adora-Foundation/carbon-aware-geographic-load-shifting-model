set terminal pdf enhanced solid font "Helvetica, 14" size 24cm,20cm # monochrome
set output "runLocationShiftingModel-effect-load-HPC.pdf"
set datafile separator comma

set yrange [0:100]
#set logscale y # 2
#set xtics 4
#set mxtics 4
set grid xtics ytics mxtics mytics

#set key autotitle columnhead
set key right top box 
set key title "" 

set title "Emmission reductions versus load" font "Helvetica,18"
set xlabel "Load" font "Helvetica,16"
set ylabel "Emissions reductions (%)" font "Helvetica,16"

set multiplot layout 2,2 rows
set title "Scenario 2" font "Helvetica,18"
plot  \
'runLocationShiftingModel-effect-load.csv' using ($1):($14) title "Actual" with linespoints lw 2 ps 0.3 pt 5,\
'runLocationShiftingModel-effect-load.csv' using ($1):($15)  title "Idle power = 0" with linespoints lw 2 ps 0.3 pt 3, \
'runLocationShiftingModel-effect-load.csv' using ($1):($16)  title "Embodied carbon = 0" with linespoints lw 2 ps 0.3 pt 4 #, \
#'runLocationShiftingModel-effect-load.csv' using ($1):($17)  title "No time constraints" with linespoints lw 2 ps 0.3 pt 5 

set title "Scenario 3" font "Helvetica,18"
plot  \
'runLocationShiftingModel-effect-load.csv' using ($1):($18) title "Actual" with linespoints lw 2 ps 0.3 pt 5,\
'runLocationShiftingModel-effect-load.csv' using ($1):($19)  title "Idle power = 0" with linespoints lw 2 ps 0.3 pt 3, \
'runLocationShiftingModel-effect-load.csv' using ($1):($20)  title "Embodied carbon = 0" with linespoints lw 2 ps 0.3 pt 4, \
'runLocationShiftingModel-effect-load.csv' using ($1):($21)  title "No time constraints" with linespoints lw 2 ps 0.3 pt 5 

set title "Scenario 4" font "Helvetica,18"
plot  \
'runLocationShiftingModel-effect-load.csv' using ($1):($22) title "Actual" with linespoints lw 2 ps 0.3 pt 5,\
'runLocationShiftingModel-effect-load.csv' using ($1):($23)  title "Idle power = 0" with linespoints lw 2 ps 0.3 pt 3, \
'runLocationShiftingModel-effect-load.csv' using ($1):($24)  title "Embodied carbon = 0" with linespoints lw 2 ps 0.3 pt 4 #, \
#'runLocationShiftingModel-effect-load.csv' using ($1):($25)  title "No time constraints" with linespoints lw 2 ps 0.3 pt 5 

set title "Scenario 5" font "Helvetica,18"
plot  \
'runLocationShiftingModel-effect-load.csv' using ($1):($26) title "Actual" with linespoints lw 2 ps 0.3 pt 5,\
'runLocationShiftingModel-effect-load.csv' using ($1):($27)  title "Idle power = 0" with linespoints lw 2 ps 0.3 pt 3, \
'runLocationShiftingModel-effect-load.csv' using ($1):($28)  title "Embodied carbon = 0" with linespoints lw 2 ps 0.3 pt 4, \
'runLocationShiftingModel-effect-load.csv' using ($1):($29)  title "No time constraints" with linespoints lw 2 ps 0.3 pt 5 

unset multiplot