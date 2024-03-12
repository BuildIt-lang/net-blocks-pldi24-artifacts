#include "nb_runtime.h"
#include <unistd.h>
#include <stdio.h>

void nb__linux_runtime_init(const char* iface);

char send_buf[1024];
char recv_buf[1024];

char client_id[] = "1.0.0.2";
char server_id[] = "1.0.0.1";

int running = 1;

static void callback(int event, nb__connection_t * c) {
	if (event == QUEUE_EVENT_READ_READY) {
		int len = nb__read(c, recv_buf, 1024);
		if (len == 16) { running = 0; return;}
		nb__send(c, recv_buf, len);
		nb__destablish(c);
	} else if (event == QUEUE_EVENT_ACCEPT_READY) {
		nb__accept(c, callback);
	}
}

int main(int argc, char* argv[]) {
        if (argc < 2) {
                printf("Usage: %s <interface name>", argv[0]);
                return -1;
        }

#ifdef MLX5
        nb__mlx5_init();
#else
	nb__linux_runtime_init(argv[1]);
#endif

        unsigned int server_id_i = ntohl(inet_addr(server_id));
        unsigned int client_id_i = ntohl(inet_addr(client_id));

        nb__my_host_id = server_id_i;
        nb__net_init();

        nb__connection_t * conn = nb__establish(nb__wildcard_host_identifier, 0, 8080, callback);

        while (running) {
                nb__main_loop_step();
        }
        nb__destablish(conn);
        return 0;
}
