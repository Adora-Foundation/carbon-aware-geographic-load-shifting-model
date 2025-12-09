runhaskell runLocationShiftingModel-tables.hs > tables.tex
runhaskell runLocationShiftingModel-effect-load.hs >  runLocationShiftingModel-effect-load.csv
gnuplot runLocationShiftingModel-effect-load.gnuplot && open runLocationShiftingModel-effect-load.pdf
gnuplot runLocationShiftingModel-effect-load-HPC.gnuplot && open runLocationShiftingModel-effect-load-HPC.pdf
