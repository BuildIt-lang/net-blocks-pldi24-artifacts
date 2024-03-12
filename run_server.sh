#!/bin/bash

set -e

if [ "$#" -ne 1 ]; then
echo "Usage: $0 <interface>"
exit -1
fi



run_one() {
	echo "Running server for $1 protocol on interface = $2"
	sudo ./scratch/$1/server $2
}


run_one udp-like $1
run_one udp-oe $1
run_one inorder $1
run_one reliable $1
run_one signalling $1
run_one checksumming $1
run_one shrunk $1
