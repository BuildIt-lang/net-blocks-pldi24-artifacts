#include "nb_runtime.h"
#include <stdio.h>
#include <unistd.h>
#include "utils.h"

void nb__linux_runtime_init(const char* iface);

char send_buf[1024];
char recv_buf[1024];

char client_id[] = "1.0.0.2";
char server_id[] = "1.0.0.1";

int running = 1;

long long start_time;
long long end_time;

long long stats[2000] = {0}; // 0 - 200 microsecond at granularity of 0.1 microsecond

int count = 0;
int packet_size = 256;

static void callback(int event, nb__connection_t * c) {
	if (running == 0) return;

        if (event == QUEUE_EVENT_READ_READY) {
                char buff[65];
                int len = nb__read(c, recv_buf, 1024);

                end_time = get_time_in_ns();

                long long elapsed_time = (end_time - start_time) / 100;

                if (elapsed_time < 2000)
                        stats[elapsed_time]++;
                count++;

                if (count == 10000) {
                        running = 0;
			nb__send(c, send_buf, 16);
                        return;
                }

                start_time = get_time_in_ns();
                nb__send(c, send_buf, packet_size);
        } else if (event == QUEUE_EVENT_ESTABLISHED) {
                start_time = get_time_in_ns();
                nb__send(c, send_buf, packet_size);
        }
}

int main(int argc, char* argv[]) {

        if (argc < 3) {
                printf("Usage: %s <interface name> <output_file>", argv[0]);
                return -1;
        }

#ifdef MLX5
        nb__mlx5_init();
#else
	nb__linux_runtime_init(argv[1]);
#endif

        unsigned int server_id_i = ntohl(inet_addr(server_id));
        unsigned int client_id_i = ntohl(inet_addr(client_id));

        nb__my_host_id = client_id_i;

        nb__net_init();


        nb__connection_t * conn = nb__establish(server_id_i, 8080, 8081, callback);

        memset(send_buf, 'x', packet_size);


        while (running) {
                nb__main_loop_step();
        }

	// Flush the terminate packet
	for (int i = 0; i < 5; i++) {
		nb__main_loop_step();
	}

        nb__destablish(conn);

        printf("DONE\n");

        FILE* f = fopen(argv[2], "w");

        long long sum = 0;
        for (int i = 0; i < 2000; i++) {
                sum += stats[i];
                fprintf(f, "%d\n", (int)sum);
        }

        fclose(f);

        return 0;

}
