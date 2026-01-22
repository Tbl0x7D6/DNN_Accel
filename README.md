# My First DNN Accelerator

System architecture and performance evaluation refer to the [report](https://github.com/Tbl0x7D6/DNN_Accel/blob/main/assets/report.pdf).

## Overview

This project is a simple implementation of a Deep Neural Network (DNN) accelerator using FPGA technology. The goal is to create a hardware accelerator that can efficiently perform DNN computations, improving performance and reducing power consumption compared to traditional CPU/GPU implementations.

During the test, I successfully ran a 7-layer convolutional neural network for handwritten digit recognition.

![Demo](./assets/demo.mp4)

## Project Structure

```
DNN_Accel
├── DNN_Accel.sdk
│   └── dnn_accel_app
│       └── src
│           ├── app.c                # Hardware control signal
│           ├── app.h
│           ├── main.c
│           └── server.c             # UDP server
│
├── DNN_Accel.srcs
│   ├── sim_1                        # Testbenches
│   │   └── new
│   │       ├── Conv_tb.sv
│   │       ├── Executor_tb.sv
│   │       ├── Pooling_tb.sv
│   │       ├── PostProcess_tb.sv
│   │       └── Top_tb.sv
│   │
│   └── sources_1
│       ├── bd
│       └── new
│           ├── PE.sv                # Processing Element
│           ├── PE_Array.sv
│           ├── AGU.sv               # Address Generation Unit
│           ├── Conv.sv
│           ├── Pooling.sv
│           ├── PostProcess.sv       # Quantization & Activation
│           ├── Executor.sv          # Single layer controller
│           ├── Top.sv
│           └── Top_Wrapper.v        # Wrapper for block design
│
└── Test_Generator
    ├── Conv.py
    ├── Executor.py
    ├── PE_Array.py
    ├── Pooling.py
    └── PostProcess.py
```

## How to Use

### Requirements

1. ZYNQ7000 FPGA Development Board AX7350B

2. Vivado and Xilinx SDK 2017.4

### Steps

1. Clone this repository and open the project in Vivado.

2. Generate bitstream.

3. Export hardware to SDK, including bitstream.

4. Open hardware manager and connect the FPGA board, including JTAG, UART and ethernet cable, where ethernet cable should be connected to `ETH1` (PS side).

5. Open SDK, `Import`-`General`-`Existing Projects into Workspace`, select the `DNN_Accel.sdk` folder, and import `dnn_accel_app` and `dnn_accel_app_bsp`.

6. Open serial port with baud rate 115200 to view the log.

7. Create `System Debugger` run configuration, select `Debug Type` as `Standalone Application Debug`, make sure the `.bit` file is included and checked all of the 4 checkboxes. In the `Application` tab, check the first processor.

8. Run. If everything is correct, you will see output like this:

    ```
    link speed for phy address 1: 1000
    [server] Started on port 7
    ```

9. You can slightly modify `main.c` to set another subnet, and config a static IP (default in `192.168.2.0/24` subnet) for your PC.

10. Run the [GUI](https://github.com/Tbl0x7D6/DNN_Accel/releases/download/Latest/dnn_accel_gui.exe) on your PC, set the IP and port as shown in the log.

11. Instructions below will run a 7-layer CNN for handwritten digit recognition.

    ```
    12205620000009012210282000000010241035102003080144083910A007080148043908A0100801880144040000043081011401A0220600FFFFFFFFFFFFFFFF
    ```

12. Upload the [weights.txt](https://github.com/Tbl0x7D6/DNN_Accel/releases/download/Latest/weights.txt).

13. Test the digit recognition feature.

### Troubleshooting

1. Before synthesis, make sure `design_1_wrapper` is the top module, if not, you can try to create HDL wrapper for the block design 1.

2. If you see log like this:

    ```
    link speed for phy address 1: 0
    ```

    after restarting SDK and rerunning the program, you may need to manully download and patch [lwip library](https://github.com/Tbl0x7D6/DNN_Accel/blob/main/DNN_Accel.sdk/dnn_accel_app_bsp/ps7_cortexa9_0/libsrc/lwip141_v2_0/src/contrib/ports/xilinx/netif/xemacpsif_physpeed.c) of bsp.

## LICENSE

This project is licensed under the GPL-3.0 License - see the [LICENSE](LICENSE) file for details.
