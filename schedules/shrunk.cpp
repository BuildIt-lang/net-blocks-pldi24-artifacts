#include "core/impls.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
using namespace net_blocks;


int main(int argc, char* argv[]) {
        if (argc < 3) {
                std::cerr << "Usage: " << argv[0] << ": <gen header file> <gen src file>" << std::endl;
                return -1;
        }
        interface_module::instance.init_module();


        identifier_module::instance.configFlowIdentifier(identifier_module::flow_identifier_t::src_dst_identifier);

        routing_module::instance.configDisableRouting();
        inorder_module::instance.configInorderStrategy(inorder_module::no_inorder);
        reliable_module::instance.configDisableReliability();
        checksum_module::instance.configDisableChecksum();

	// Add ranges on host and app identifiers and length to shrink the headers
        identifier_module::instance.set_host_range(ntohl(inet_addr("1.0.0.1")), ntohl(inet_addr("1.0.0.16")));
        identifier_module::instance.set_app_range(8079, 8095);
        payload_module::instance.set_max_length(65535);

        signaling_module::instance.configDisableSignaling();


        payload_module::instance.init_module();
        signaling_module::instance.init_module();
        inorder_module::instance.init_module();
        reliable_module::instance.init_module();
        identifier_module::instance.init_module();
        signaling_module_after::instance.init_module();
        routing_module::instance.init_module();
        checksum_module::instance.init_module();
        network_module::instance.init_module();

        net_packet.fix_layout();
        net_packet.print_layout(std::cout);

        run_nb_pipeline(argv[1], argv[2]);

        return 0;
}
