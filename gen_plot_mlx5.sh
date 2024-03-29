gnuplot plot_mlx5.sh
ps2pdf scratch/plot_mlx5.ps scratch/plot_mlx5.pdf
pdfcrop --margins '10 10 30 30' scratch/plot_mlx5.pdf scratch/latency_plot_mlx5.pdf
