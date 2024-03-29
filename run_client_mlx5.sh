#!/bin/bash

set -e

if [ "$#" -ne 1 ]; then
echo "Usage: $0 <interface>"
exit -1
fi


run_one() {
	sleep 1
	echo "Running client for $1 protocol on interface = $2"
	sudo ./scratch/$1/client_mlx5 $2 scratch/$1/cdf.txt
}

run_one udp-like $1
run_one udp-oe $1
run_one inorder $1
run_one reliable $1
run_one signalling $1
run_one checksumming $1
run_one shrunk $1  

paste scratch/udp-like/cdf.txt scratch/udp-oe/cdf.txt scratch/inorder/cdf.txt scratch/reliable/cdf.txt scratch/signalling/cdf.txt scratch/checksumming/cdf.txt scratch/shrunk/cdf.txt > scratch/cdfs.txt

bash gen_plot.sh
