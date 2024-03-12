# NetBlock Artifact Evaluation

## Introduction
This repository documemts the evaluation procedure for the artifacts of our PLDI 2024 paper titled "NetBlocks: Staging Layouts for High-Performance Custom Host Network Stacks". NetBlocks is a network DSL compiler built on top of the multi-stage programming framework [BuildIt](https://buildit.so). 
NetBlocks adds a custom layout layer on top of BuildIt to generate modular layouts for binary data on the packet along with using high-performance staged Aspect Oriented Programming for modular features development and selection. The artifacts are divided into 3 parts - 
1. Inspect the generated code and layouts for different network protocol configurations
2. Evaluate round-trip latency of the various protocols and compare the performance to feature tradeoff (Fig 21. in the attached paper)
3. Count the lines of code for all modules (Fig. 20 in the attached paper)

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

    bash build_all.sh

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

