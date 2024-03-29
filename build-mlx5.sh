set -e

# Make sure buildit is built
make -C net-blocks/buildit -j$(nproc)

# Make sure net-blocks is built with MLX5 support
echo "RDMA_CORE_PATH=/local/software/rdma-core/build" > net-blocks/Makefile.inc
make -C net-blocks -j$(nproc)
make -C net-blocks simple_test
make -C net-blocks simple_network_test

# Next we will compile each schedule
mkdir -p scratch

compile_schedule() {
	echo "Building schedule "$1
	mkdir -p scratch/$1	
	c++ -o scratch/$1/gen schedules/$1.cpp -rdynamic -L net-blocks/buildit/build -L net-blocks/build -lnet_blocks -lbuildit -std=c++11 -O3 -fno-move-loop-invariants -I net-blocks/include -I net-blocks/buildit/include

	./scratch/$1/gen scratch/$1/gen_headers.h scratch/$1/nb_simple.c > scratch/$1/proto.txt

	cc -O3 -c scratch/$1/nb_simple.c -o scratch/$1/nb_simple.o -I net-blocks/runtime -I scratch/$1/ -fno-strict-aliasing
	cc -O3 -c net-blocks/runtime/nb_runtime.c -o scratch/$1/nb_runtime_simple.o -I net-blocks/runtime -I scratch/$1/ -fno-strict-aliasing
	c++ -O3 -c net-blocks/runtime/nb_mlx5_transport.cc -o scratch/$1/nb_mlx5_transport.o -I net-blocks/runtime -I scratch/$1/ -fno-strict-aliasing -I /local/software/rdma-core/build/include -I net-blocks/runtime/mlx5_impl/
}


gen_schedule() {
	compile_schedule $1	

	cc -O3 -DMLX5 src/server.c -o scratch/$1/server_mlx5.o -I net-blocks/runtime -I scratch/$1/ -fno-strict-aliasing  -c
	cc -O3 -DMLX5 src/client.c -o scratch/$1/client_mlx5.o -I net-blocks/runtime -I scratch/$1/ -fno-strict-aliasing  -c

	c++ -o scratch/$1/server_mlx5 scratch/$1/server_mlx5.o scratch/$1/nb_simple.o scratch/$1/nb_runtime_simple.o  net-blocks/build/runtime/nb_timer.o scratch/$1/nb_mlx5_transport.o net-blocks/build/runtime/mlx5_impl/transport.o net-blocks/build/runtime/mlx5_impl/halloc.o -L/local/software/rdma-core/build/lib -Wl,--rpath,/local/software/rdma-core/build/lib -libverbs -lmlx5
	c++ -o scratch/$1/client_mlx5 scratch/$1/client_mlx5.o scratch/$1/nb_simple.o scratch/$1/nb_runtime_simple.o  net-blocks/build/runtime/nb_timer.o scratch/$1/nb_mlx5_transport.o net-blocks/build/runtime/mlx5_impl/transport.o net-blocks/build/runtime/mlx5_impl/halloc.o -L/local/software/rdma-core/build/lib -Wl,--rpath,/local/software/rdma-core/build/lib -libverbs -lmlx5
}

gen_schedule_signal() {
	compile_schedule $1	
	cc -O3 -DMLX5 src/signal_server.c -o scratch/$1/server_mlx5.o -I net-blocks/runtime -I scratch/$1/ -fno-strict-aliasing  -c 
	cc -O3 -DMLX5 src/signal_client.c -o scratch/$1/client_mlx5.o -I net-blocks/runtime -I scratch/$1/ -fno-strict-aliasing  -c

	c++ -o scratch/$1/server_mlx5 scratch/$1/server_mlx5.o scratch/$1/nb_simple.o scratch/$1/nb_runtime_simple.o  net-blocks/build/runtime/nb_timer.o scratch/$1/nb_mlx5_transport.o net-blocks/build/runtime/mlx5_impl/transport.o net-blocks/build/runtime/mlx5_impl/halloc.o -L/local/software/rdma-core/build/lib -Wl,--rpath,/local/software/rdma-core/build/lib -libverbs -lmlx5
	c++ -o scratch/$1/client_mlx5 scratch/$1/client_mlx5.o scratch/$1/nb_simple.o scratch/$1/nb_runtime_simple.o  net-blocks/build/runtime/nb_timer.o scratch/$1/nb_mlx5_transport.o net-blocks/build/runtime/mlx5_impl/transport.o net-blocks/build/runtime/mlx5_impl/halloc.o -L/local/software/rdma-core/build/lib -Wl,--rpath,/local/software/rdma-core/build/lib -libverbs -lmlx5
}

gen_schedule udp-like
gen_schedule udp-oe
gen_schedule inorder
gen_schedule reliable
gen_schedule_signal signalling
gen_schedule checksumming
gen_schedule shrunk
