gnuplot plot.sh
ps2pdf scratch/plot.ps scratch/plot.pdf
pdfcrop --margins '10 10 30 30' scratch/plot.pdf scratch/latency_plot.pdf
