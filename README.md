# NetBlock Artifact Evaluation

## Introduction
This repository documemts the evaluation procedure for the artifacts of our PLDI 2024 paper titled "NetBlocks: Staging Layouts for High-Performance Custom Host Network Stacks". NetBlocks is a network DSL compiler built on top of the multi-stage programming framework [BuildIt](https://buildit.so). 
NetBlocks adds a custom layout layer on top of BuildIt to generate modular layouts for binary data on the packet along with using high-performance staged Aspect Oriented Programming for modular features development and selection. The artifacts are divided into 5 parts - 
1. Inspect the generated code and layouts for different network protocol configurations
2. Evaluate round-trip latency of the various protocols and compare the performance to feature tradeoff (Fig 21. in the attached paper)
3. Count the lines of code for all modules (Fig. 20 in the attached paper)
4. Evaluate round-trip latency of the various protocols and compare the performance to feature tradeoff on the same hardware as in the paper (MLX Connect-X 5)
5. Demonstrate extensibility/reusability of the system by implementing a simple "encryption" module.

Source code for the core framework, all implemented modules, the 7 configurations from the paper and the dependencies (BuildIt) are packaged into this repo as submodules. 

## Hardware and Software requirements
We expect you to run the code on a Linux system (tested with Ubuntu 22.04). If you do not have access to any supported systems, please contact us. We can share access to our systems. We expect the system to have around 1 GB free space. Windows Subsystem for Linux is also supported as long as the dummy interface is used to evaluate. 
For the evaluation in the paper, we used special servers with Mellanox Connect-X5 cards attached. These cards offer kernel bypass, 100 gbps of bandwidth and single digit microsecond latency. Evaluating on this hardware highlights the difference between the protocols better. We are currently working on getting the reviewers (root) access to our systems to replicate the exact numbers. 
In the meantime, the evaluation can be run on any 2 servers attached with an ethernet network or a single system by the means of a dummy interfact (we will explain this below). The evaluation without the Mellanox card does highlight the difference between some protocol configurations but the exact numbers would not be same as the paper. 
However the main point of the paper that NetBlocks offers a tradeoff between features and performance still stands true. 

Following are the software requirements for all the sections - 
1. g++ >= 7.5 (comparable clang++ would also work)
2. make (GNU make >= 4.1)
3. bash
4. git
5. gnuplot
6. ps2pdf (from texlive-latex-extra)
7. pdfcrop (from texlive-extra-utils)

All the required packages can be installed with standard package managers like `apt`. 

Since network experiments require direct access to the network card, you would also need root access on the server/computer used for evaluation. 

## How to run

### Cloning the repository

To start, first clone this repository using the following command -

    git clone --recursive https://github.com/BuildIt-lang/net-blocks-pldi24-artifacts.git

If you have already cloned the repository without the recursive flag, you can run the following command inside the cloned directory to fetch all the submodules -

    git submodule update --init --recursive

Now navigate to the main repostitory and continue the rest of the steps.

### Build all modules

First we will compile the dependency BuildIt, the NetBlocks core framework and all the modules and also genearate the specialized protocols for all the 7 configurations listed in Fig 19 of the paper. We have provided a single script that does all the aforementioned tasks. Run the command - 

    bash build-all.sh

The command should first build all the packages and print a message for each configuration it compiles. If any of the steps fails, the script should print an error and fail. Please fix the error and run the script again and it should continue where it left off. 

As for possible errors, one source of error could arise from the fact that BuildIt is compiled with -Werror. This means all warnings are treated as errors. If your compiler version detects some warning, the compilation would fail. One easy way to fix this would be to remove `-Werror` from `net-blocks/buildit/make/setvars.mk` on line 15. 

If everything compiles and generates correctly, the script should complete without any errors. 

Now we are ready to look at the generated protocol and code in Section 1. 

## Section 1: Inspect generated protocols and implementation

For our evaluation, we are comparing 7 different custom protocols as mentioned in Fig 19 of the paper. These configurations are - UDP-Like, UDP-Over-Ethernet, Inorder, Reliable, Signalling, Checksumming and Shrunk. The input schedule for each of these are provided under the `schedules/` directory. Please view a few of these files to see how different modules are configured and initialized to generate differnet protocols. One of the interesting protocols to look at is the `schedules/shrunk` protocol. 
In this protocol, we restrict the range of the host identifiers (equivalent to MAC address/IP address) to a range of 16 addresses bringing down the required bits to just 4. We also restrict the range of the app identifiers (similar to port numbers) to a range of 16 values again requiring 4 bits. We also cap the max length to 65536 to shrink the number of bits for the length field to be 16. 
This protocol packs the entire header into just 4 bytes. 

After viewing the protocol specification in the input file, we will look at the generated protocol layout. Open the file `scratch/shrunk/proto.txt`. This file is generated by the compiler and prints the headers for the protocol. The headers are further grouped into separate sections for enforcing different optimization policies. These groups are demarkated by the dashed lines. In this file, we can ignore the first group of headers, since these are non-network headers that are just used locally in the stack implementation for packet level book keeping and are not actually transmitted on the wire. For the rest of the header fields, we can see the length and the offset printed next to the field. These values are computed by the `get_offset()` and `get_size()` functions in the dynamic fields as explained in the paper. 
We can notice for the shrunk fields, the number of bits for the headers match the sizes we had calculated before. Feel free to edit the `scratch/shrunk/proto.txt` to edit the ranges and recompile with `bash build_all.sh`. You should be able to see the change reflected in the generated protocol layout. 

Please revert the changes if any and rebuild the system before running the actual evaluations.

Next we will briefly look at the generated code. Open the file `scratch/shrunk/nb_simple.c`. This file contains the entire protocol implementation split into the functions - `nb__net_init`, `nb__establish`, `nb__destablish`, `nb__send`, `nb__run_ingress_step`, `nb__reliable_redelivery_timer_cb`. These functions implement the logic for the various "paths" in the generated stack as described in the paper. 
As you can see the generated code is very gnarly and not suitable for reading but implements the protocol in an optimized way (with no virtual dispatches or expensive offset computations, even though the modules are implemented in a very modular way). For the shrunk protocol, you can notice a lot of bitmasking and shifting under the `nb__send` and `nb__run_ingress_step` functions since these functions access the shrunk fields. 
Feel free to navigate to other protocols under `scratch/*` and notice the difference in the protocol layout (`proto.txt`) and generated implementation (`nb_simple.c`). 

Feel free to also count the lines of code for the generated protocols and match them with Fig. 19 in the paper. 


## Section 2: Evaluate the latency of the generated protocols

For this section, we will reproduce the results in Fig 21 of the paper. This evaluation measures the round trip latency of 256 byte messages measured across 10000 requests for the 7 protocols. The purpose of this evaluation is to show the tradeoff in the features vs performance which is the main purpose of NetBlocks. We do not replicate the evaluation for Fig. 22 and Fig 23 (Nginx and underwater robotics respectively) because they follow similar trends and are included in the paper to demonstrate NetBlocks's compatibility with real applications. The core latency results are similar to the Fig 21. These other evaluations required more setup and can be included if the reviewers request.

As explained before for the evaluation in the paper, we used systems with specific high-performance network cards. We are working on getting you root access to these, but in the meantime you can run the evaluation with any standard ethernet network card or on a single system with a dummy interface. 

You can run the evaluation on two servers connected directly with an ethernet cable. We would recommend avoiding systems connected with a hub or switch since some devices drop non-standard protocol packets. NetBlocks is all about creating custom protocols and might not run on these devices. If you do not have access to two servers connected with a cable, you can simulate the scenario on a single system by creating a dummy interface and running the code all on one server. If you plan to use two servers, please clone and build this repo on both the servers by following the steps above. If you plan to use the dummy interface route, please create a dummy interface with the commands - 

    sudo ip link add dummy0 type dummy
    sudo ifconfig dummy0 up

We will need the interface name for the steps ahead. If you are using the dummy interface, this name would be `dummy0`. If you are using an actual interface, please notedown the interface name of both the servers. Please also make sure the interfaces are "UP". They do not need to be assigned an IP address since we are implementing this protocols ourselves. If you are using an actual interface, we also recommend turning off LLDP (low level discovery protocol) on both the nodes with the command - `sudo systemctl stop lldpd` or equivalent for your system. This ensures that other packets do not interfere with our experiments. This is typically not a big issue since our experiments finish within a minute and LLDP messages are exchanged around every 10 mins. If you are not able to disable LLDPD, it should be fine. If the experiments gets stuck or crashes, just run it again. 

If you have the interface names written down for both the hosts (`dummy0` for both if a single system is used), proceed to the next step. 

We have provided a single script that runs 10000 requests for all configurations one after the other, collects the CDF (cummulative distribution functions) and plots them on a graph. 

Select one of the nodes to be the server and first run on it the command from the top level directory  - 

    bash run_server.sh <interface>

(replace `<interface>` with the name of the interface on that host or `dummy0` if using dummy interface). 

This command will prompt for your `sudo` password. Please enter it before running the client. 

On the other node (or just a different terminal if using dummy), run the command from the top level directory - 

    bash run_client.sh <interface>

(replace `<interface>` with the name of the interface on that host or `dummy0` if using dummy interface). 

This command will also prompt for your `sudo` password. Please enter it now. 

If the commands execute correctly, the output should print `DONE` 7 times and produce a file - `scratch/latency_plot.pdf`. View this file in your favorite pdf and observe the plots. You should see 7 parallel plots showing varying latency of the different protocols just like in the paper. Unlike the paper some plots might be very close to each other, since the difference between them is order of a fraction of microseconds which is demonstrated well only with the high-end interface cards. Although, you should still be able to see a significat difference with Signalling and Reliable schemes (like in the paper), since these require extra messages to implement the logic significantly increasing the round-trip latency. These results are explained in the evaluation section of the paper. 



## Section 3: Measuring lines of code for the modules and core

Finally, we will quickly look at the implementation complexity of the system by measuring the lines of code for the core and each module as shown in Fig. 20 of the paper. 
To measure the lines of code of the core run the command - 

    wc -l net-blocks/include/core/* net-blocks/src/core/*

The total lines of code should be roughly the same as the paper. You can measure the lines of code for each module by running the command - 

    wc -l net-blocks/include/modules/* net-blocks/src/modules/*

This should print the lines of code for the header and the source file for each module. Adding the numbers up should be close to the numbers in the Fig. 20. 

Finally, for the runtime, run the command - 

    wc -l $(find -wholename "./net-blocks/runtime/*")

This should roughly match the final row in Fig. 20. This excercise shows that the implementation complexity of the modules (and hence new features) is relatively small as compared to the framework. The framework itself that generates all this code is not large since it is built on top of BuildIt. Feel free to browse the implementation of the core framework and the modules to get a better sense of the implementation complexity. 


## Section 4: Run Echo evaluation on our servers

In this section, we will run the evaluation in Fig 21 on the same hardware that we used in the paper - 2 servers with a Mellanox Connect-X 5 NICs with 100Gpbs bandwidth and support for kernel bypass technology. For this section we have provided access to our servers. 
The password for the servers should be shared on hotcrp as a comment. The instructions to connect are as below. Let us begin by trying to connect to our servers. 

Since the servers (and the VMs) are behind our lab's firewalls, the command to ssh is a little long. Try running the following command to connect - 

    ssh aeuser@netblocks-host1 -J aeuser@royal.csail.mit.edu,aeuser@zet1.csail.mit.edu

This command should prompt you for a password 3 times (once for each of the three hosts involved in the hops). Paste the same password thrice. If everything works correctly you should be presented with a prompt `aeuser@netblocks-host1 $`. Try connecting to the second server with - 

    ssh aeuser@netblocks-host2 -J aeuser@royal.csail.mit.edu,aeuser@zet2.csail.mit.edu

Once again you should be prompted for the password 3 times. Enter the same password. Notice that the above command has 2 differences from the command before (netblocks-host2 and zet2 instead of netblocks-host1 and zet1). 

If you are able to connect to both the servers, we request you to make a working directory for yourself in the home directory (to separate your files from the other reviewers). Feel free to name the directory whatever you like. We also request you to coordinate between yourseves on using the servers. Please don't run the experiments at the same time, they will most likely fail if two reviewers try to access the NIC at the same time. You can run the command `finger` on the servers to check if any else is logged in as the user `aeuser` (One output line means it is just you). This also means if you are done with the experiments, please exit the server and dont' leave any screen/tmux sessions behind so other reviewers can get a green light to run their experiments. 

Start by cloning this repo on both the servers in your working directory (once again with the `--recursive` flag). Follow the steps from **Cloning the repository** and **Build all modules** like above. Do this on both the servers. 

Next we will also build the versions of the test cases that use the NIC. Run the command on both the servers in the top level working directory of the cloned repo - 

    bash build-mlx5.sh

This command should complete without errors. All build dependencies have been installed on both the servers. Next we will make sure the interfaces are up and running. Start by running the command `ifconfig` on both the servers. You should see the interface `enp7s0` on both the servers. If it is not visible, you can bring it up with the command - 

    sudo ifconfig enp7s0 up

You have been given root access on both the servers without password, so this command should just run. 

If everything is ready, let us run the test cases. On one of the server say `netblocks-host1` run the command - 

    bash run_server_mlx5.sh enp7s0

and on the other one run - 

    bash run_client_mlx5.sh enp7s0

Both the servers are symmetric, so the commands can be run on either servers. Just make sure to run the two commands on different servers. The test cases will take a while to run (2 mins) (mainly becauses it pauses between runs to get stable numbers). If everything runs correctly, a plot should be generated under `scratch/latency_plot_mlx5.pdf`. 

There is small chance the experiments crash. This happens if a random other packet is sent over the network which sometimes happens due to LLDP packets showing up. If this happens, just run the last step again and it should pass. 

Finally, you won't be able to directly view the plot pdf on the systems or scp them trivially due to the extra hops. Suppose you ran the client on `netblocks-host2`, you can use the following command **on your computer** to download the plot - 

    ssh aeuser@netblocks-host2 -J aeuser@royal.csail.mit.edu,aeuser@zet2.csail.mit.edu 'cat /home/aeuser/<your directory>/net-blocks-pldi24-artifacts/scratch/latency_plot_mlx5.pdf' > latency_plot_mlx5.pdf

This command again prompt you for the password 3 times. But should save a file `latency_plot_mlx5.pdf` in your current working directory. Open the pdf in your favorite pdf viewer and you should see a plot like the one in the paper. One key difference you might notice that the latency of all the lines is higher by half a microsecond. This happens because the hosts we have given you are VMs on the servers (due to the requirement for root access) and mapping physical NICs to VMs requires turning on [Intel IO_MMU](https://en.wikipedia.org/wiki/Input%E2%80%93output_memory_management_unit) which is known to have a slight overhead. Neverthless, this overhead applies to all the lines and just offsets all the lines, still maintaining the main takeaway of the paper. At the same time, the exact latency number are in the same single digit microsecond latency like in the paper as compared to the experiments before. To confirm that this overhead is indeed because of IOMMU, we ran the exact same steps directly on the hosts (outside the VMs) and attached the plot in this repo as `reference_latency_plot_mlx5.pdf` which is similar to the numbers in the paper. 

## Section 5: Demonstrate extensibility of the system

One of the main contributions of the paper that sets NetBlocks apart from other network DSL compilers is that apart from creating new protocols from existing features networks engineers and researches can implement new features by just writing "library like" code and no compilers knowledge. To demonstrate this and the reusability of the system we will implement a dummy encryption module that just ciphers the bytes of the payload before sending and unciphers it on receiving it. This will involve generating a loop to iterate through the payload bytes and modify them. In a traditional compiler this would require writing creating IR nodes for the loops or just generate the code, but with NetBlocks we just have to add a new module that implements this feature. 


You can run the following steps on either on your own system or on our servers. It should be the same. If you do it on your own server, you can use your favorite editor. On our servers, we have `vim` and `nano` installed.  

Let us start by first defining the class for this new module. Create a new file `net-blocks/include/modules/encryption.h` and add the contents - 

```
#ifndef NBX_ENC_H
#define NBX_ENC_H
#include "core/framework.h"

namespace net_blocks {
class encryption_module: public module {
public:
        void init_module(void);
        module::hook_status hook_send(builder::dyn_var<connection_t*> c, packet_t,
                builder::dyn_var<char*> buff, builder::dyn_var<unsigned int> len, builder::dyn_var<int*> ret_len);
        module::hook_status hook_ingress(packet_t);
private:
        encryption_module() = default;
public:
        static encryption_module instance;
        const char* get_module_name(void) override { return "EncryptionModule"; }
};
}
#endif
```

What we have done here is that we have created a new class `encryption_module` that extends the `module` type and we have overridden a few functions including the `init_module` function and the `hook_send` and `hook_ingress` functions. This is because the "encryption" feature will change the logic for sending a packet and receiving a packet. If further changes need to be done while establishing and destablishing a connection (like handshakes to exchange keys), the corresponding hook functions can also be extended. We have made the constructor of the class to be private and made a static instance to make this class into singleton class. Finally we have implemented the `get_module_name` function which helps with debugging. 

Let us now implement the hook functions. Create a new file - `net-blocks/src/modules/encryption.cpp` and add the contents - 

```
#include "modules/encryption.h"

namespace net_blocks {
encryption_module encryption_module::instance;

void encryption_module::init_module(void) {
        // Register this module in the compiler pipeline
        framework::instance.register_module(this);
}
module::hook_status encryption_module::hook_send(builder::dyn_var<connection_t*> c, packet_t p, builder::dyn_var<char*> buff, builder::dyn_var<unsigned int> len, builder::dyn_var<int*> ret_len) {
        // Identify the address of the payload and the payload length from the packet
        builder::dyn_var<unsigned char*> payload = net_packet["payload"]->get_addr(p);
        builder::dyn_var<unsigned int> payload_len = net_packet["computed_total_len"]->get_integer(p) - (net_packet.get_total_size() - get_headroom() - 1);
        // Iterate through each byte and "encrypt" it
        for (builder::dyn_var<int> i = 0; i < payload_len; ++i)
                payload[i] = (payload[i] + 0x55) % 256;
        return module::hook_status::HOOK_CONTINUE;
}
module::hook_status encryption_module::hook_ingress(packet_t p) {
        // Identify the address of the payload and the payload length from the packet
        builder::dyn_var<unsigned char*> payload = net_packet["payload"]->get_addr(p);
        builder::dyn_var<unsigned int> payload_len = net_packet["computed_total_len"]->get_integer(p) - (net_packet.get_total_size() - get_headroom() - 1);
        // Iterate through each byte and "decrypt" it
        for (builder::dyn_var<int> i = 0; i < payload_len; ++i)
                payload[i] = (payload[i] + (256 - 0x55)) % 256;
        return module::hook_status::HOOK_CONTINUE;
}
}
     
```

Besides defining the instance of the module, we have defined the hook implementations. For the hook_send function, we obtain the start of the payload and the length of the payload. We then have a for loop that iterates over each value and performs a simple cipher on it. 
Notice that all this code looks exactly how you would write it in a library except it uses BuildIt's dyn_var type for generating the code in the second stage. Similarly we implement the hook_ingress function, we perform the reverse of the send function. 

Finally, we will activate the module by editing `net-blocks/src/impls/simple.cpp` and first adding the header `#include "modules/encryption.h" and then adding the line **before** the `checksum_module` is initialized  -

    encryption_module::instance.init_module();
    // Next line should be checksum_module::instance.init_module();

Notice we insert the encryption before the checksum module so that checksumming is performed after the changes to the payload. And that is it, our new module is inserted into the compiler pipeline. Let us generate the new protocol with this implementation by running the command - 

    make -C net-blocks simple_test

If everything is done correctly the build should complete. Before we run the generated code, let us inspect it to check if our logic has been inserted. Open `net-blocks/scratch/nb_simple.c` in our favorite editor. and scroll to the `nb__send` function. Around line 194 we should see our newly added logic for encryption and around line 262 under the `nb__run_ingress_step` function we should see the decryption logic. Notice this doesn't have overheads of the virtual functions we created. 

Now let us run our new protocol to check if everything is correct by running the commands - 

    ./net-blocks/build/test/simple_server &
    ./net-blocks/build/test/simple_client

If everything run correctly, the client and server should print the messages they received. Feel free to comment out of say the decryption loop from the `hook_ingress` hook function we added under `net-blocks/src/modules/encryption.cpp` and running all the steps to see that the programs now print gibberish, because the payload is handed over to the user as it is.  

This concludes the artifact evaluation for the paper. If the reviewers wish to reproduce any more results from the paper, please reach out to us and we are happy to provide instructions. 



