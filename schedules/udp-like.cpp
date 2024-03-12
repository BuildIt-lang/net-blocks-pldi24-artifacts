#include "core/impls.h"

using namespace net_blocks;


int main(int argc, char* argv[]) {
	if (argc < 3) {
		std::cerr << "Usage: " << argv[0] << ": <gen header file> <gen src file>" << std::endl;
		return -1;
	}
	interface_module::instance.init_module();

	// UDP Compat inserts all fields that are required for binary
	// compatibility for both UDP and IP layers. Does not change behavior in anyway
	framework::instance.compat_level = compat_level_t::UDP_COMPAT;
	identifier_module::instance.configFlowIdentifier(identifier_module::flow_identifier_t::src_dst_identifier);

	routing_module::instance.configEnableRouting();
	inorder_module::instance.configInorderStrategy(inorder_module::no_inorder);
	reliable_module::instance.configDisableReliability();
	checksum_module::instance.configDisableChecksum();
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
