#!/bin/bash

set -e

if [ "$#" -ne 1 ]; then
echo "Usage: $0 <interface>"
exit -1
fi


run_one() {
	sleep 1
	echo "Running client for $1 protocol on interface = $2"
	sudo ./scratch/$1/client_mlx5 $2 scratch/$1/cdf_mlx5.txt
}

run_one udp-like $1
run_one udp-oe $1
run_one inorder $1
run_one reliable $1
run_one signalling $1
run_one checksumming $1
run_one shrunk $1  

paste scratch/udp-like/cdf_mlx5.txt scratch/udp-oe/cdf_mlx5.txt scratch/inorder/cdf_mlx5.txt scratch/reliable/cdf_mlx5.txt scratch/signalling/cdf_mlx5.txt scratch/checksumming/cdf_mlx5.txt scratch/shrunk/cdf_mlx5.txt > scratch/cdfs_mlx5.txt

bash gen_plot_mlx5.sh
