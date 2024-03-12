set size ratio 0.5
set terminal postscript color
set output "scratch/plot.ps"
set terminal postscript size 600,300
set terminal postscript font 'Helvetica,15'
set xlabel 'Round-Trip Latency (us)'
set ylabel 'CDF' offset 2
set style lines 1 lw 2 lc "#1b9e77" pt 1 ps 2
set style lines 2 lw 2 lc "#d95f02" pt 1 ps 2
set style lines 3 lw 2 lc "#7570b3" pt 1 ps 2
set style lines 4 lw 2 lc "#e7298a" pt 1 ps 2
set style lines 5 lw 2 lc "red" pt 1 ps 2
set style lines 6 lw 2 lc "green" pt 1 ps 2
set style lines 7 lw 2 lc "black" pt 1 ps 2
set key left
set xrange [0:10]
plot    "scratch/cdfs.txt" using ($0/10):($1/10000) with lines ls 1 title "UDP-Like", \
        "scratch/cdfs.txt" using ($0/10):($2/10000) with lines ls 2 title "UDP-over-Ethernet", \
        "scratch/cdfs.txt" using ($0/10):($3/10000) with lines ls 3 title "Inorder", \
        "scratch/cdfs.txt" using ($0/10):($4/10000) with lines ls 4 title "Reliable", \
        "scratch/cdfs.txt" using ($0/10):($5/10000) with lines ls 5 title "Signalling", \
        "scratch/cdfs.txt" using ($0/10):($6/10000) with lines ls 6 title "FullChecksumming", \
        "scratch/cdfs.txt" using ($0/10):($7/10000) with lines ls 7 title "ShrunkFields"
