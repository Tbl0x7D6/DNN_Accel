`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/08/2025 03:19:26 PM
// Design Name: 
// Module Name: PE_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench for PE module - 1D Convolution
// 
// Dependencies: PE.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// Test the timing behavior of PE module for 1D convolution
// - Test 3x3 convolution, stride=1
// - Test 3x3 convolution, stride=2
// - Test 5x5 convolution, stride=1
// - Test 5x5 convolution, stride=2
//////////////////////////////////////////////////////////////////////////////////


module PE_tb();

    // Clock and control signals
    reg clk;
    reg start;
    reg kernel_type;  // 0: 3x3, 1: 5x5
    reg stride;       // 0: 1,   1: 2
    
    // Data input
    reg [7:0] ifm_data1 [35:0];
    reg [7:0] ifm_data2 [35:0];
    reg [7:0] filter_data [4:0];
    reg [20:0] psum_data1;
    reg [20:0] psum_data2;
    
    // Output
    wire [20:0] psum_out1;
    wire [20:0] psum_out2;
    
    // Clock generation: 10ns period (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // PE module instantiation
    PE uut (
        .clk(clk),
        .start(start),
        .kernel_type(kernel_type),
        .stride(stride),
        .ifm_data1(ifm_data1),
        .ifm_data2(ifm_data2),
        .filter_data(filter_data),
        .psum_data1(psum_data1),
        .psum_data2(psum_data2),
        .psum_out1(psum_out1),
        .psum_out2(psum_out2)
    );
    
    // Auxiliary variables
    integer i;
    
    // Initialization task
    task init_signals;
        begin
            start = 0;
            kernel_type = 0;
            stride = 0;
            psum_data1 = 0;
            psum_data2 = 0;
            
            // Initialize input feature map data
            for (i = 0; i < 36; i = i + 1) begin
                ifm_data1[i] = i + 1;  // 1, 2, 3, ..., 36
                ifm_data2[i] = 36 - i;  // 1, 2, 3, ..., 36
            end
            
            // Initialize filter data
            for (i = 0; i < 5; i = i + 1) begin
                filter_data[i] = i + 1;  // 1, 2, 3, 4, 5
            end
        end
    endtask
    
    // Display test result task
    // task display_result;
    //     input [7:0] test_num;
    //     input [255:0] test_name;
    //     begin
    //         $display("========================================");
    //         $display("Test %0d: %s", test_num, test_name);
    //         $display("Time: %0t ns, psum_out = %0d", $time, psum_out);
    //         $display("========================================");
    //     end
    // endtask
    
    // Main test flow
    initial begin
        $display("========================================");
        $display("PE module 1D convolution test starts");
        $display("Time: %0t", $time);
        $display("========================================");
        
        // Initialization
        init_signals();
        #20;
        
        //====================================================================
        // Test 1: 3x3 convolution, stride=1
        // Expected: Complete one output point calculation every 3 clock cycles
        // First output: ifm[0]*filter[0] + ifm[1]*filter[1] + ifm[2]*filter[2]
        //             = 1*1 + 2*2 + 3*3 = 1 + 4 + 9 = 14
        //====================================================================
        $display("\n[Test 1] 3x3 convolution, stride=1");
        $display("Input feature map: [1,2,3,4,5]");
        $display("Convolution kernel: [1,2,3]");
        
        kernel_type = 0;  // 3x3
        stride = 0;       // stride=1
        psum_data1 = 0;
        psum_data2 = 0;
        
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        repeat(7) @(posedge clk);
        
        // // Output point 1: positions [0,1,2]
        // for (i = 0; i < 3; i = i + 1) begin
        //     @(posedge clk);
        //     $display("T=%0t: Cycle %0d - MAC[%0d]: ifm[%0d]*filter[%0d]=%0d*%0d, psum_out=%0d", 
        //              $time, i+1, i, i, i, ifm_data[i], filter_data[i], psum_out);
        // end
        
        // // Output point 2: positions [1,2,3]
        // for (i = 0; i < 3; i = i + 1) begin
        //     @(posedge clk);
        //     $display("T=%0t: Cycle %0d - MAC[%0d]: ifm[%0d]*filter[%0d]=%0d*%0d, psum_out=%0d", 
        //              $time, i+4, i, 1+i, i, ifm_data[1+i], filter_data[i], psum_out);
        // end
        
        // // Output point 3: positions [2,3,4]
        // for (i = 0; i < 3; i = i + 1) begin
        //     @(posedge clk);
        //     $display("T=%0t: Cycle %0d - MAC[%0d]: ifm[%0d]*filter[%0d]=%0d*%0d, psum_out=%0d", 
        //              $time, i+7, i, 2+i, i, ifm_data[2+i], filter_data[i], psum_out);
        // end
        
        // // Output point 4: positions [3,4,5]
        // for (i = 0; i < 3; i = i + 1) begin
        //     @(posedge clk);
        //     $display("T=%0t: Cycle %0d - MAC[%0d]: ifm[%0d]*filter[%0d]=%0d*%0d, psum_out=%0d", 
        //              $time, i+10, i, 3+i, i, ifm_data[3+i], filter_data[i], psum_out);
        // end
        
        // start = 0;
        // @(posedge clk);
        // display_result(1, "3x3 convolution, stride=1");
        
        // #50;
        
        //====================================================================
        // Test 2: 3x3 convolution, stride=2
        // Expected: Complete one output point every 3 clock cycles, but positions jump by 2
        // First output: ifm[0]*filter[0] + ifm[1]*filter[1] + ifm[2]*filter[2] = 14
        // Second output: ifm[2]*filter[0] + ifm[3]*filter[1] + ifm[4]*filter[2] = 3+8+15 = 26
        //====================================================================
        $display("\n[Test 2] 3x3 convolution, stride=2");
        $display("Input feature map: [1,2,3,4,5,6,7]");
        $display("Convolution kernel: [1,2,3]");
        
        kernel_type = 0;  // 3x3
        stride = 1;       // stride=2
        psum_data1 = 0;
        psum_data2 = 0;
        
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        repeat(3) @(posedge clk);
        psum_data1 = 2;
        repeat(2) @(posedge clk);
        psum_data1 = 0;
        repeat(2) @(posedge clk);
        
        // // Output point 1: positions [0,1,2]
        // for (i = 0; i < 3; i = i + 1) begin
        //     @(posedge clk);
        //     $display("T=%0t: Cycle %0d - MAC[%0d]: ifm[%0d]*filter[%0d]=%0d*%0d, psum_out=%0d", 
        //              $time, i+1, i, i, i, ifm_data[i], filter_data[i], psum_out);
        // end
        
        // // Output point 2: positions [2,3,4] (stride=2)
        // for (i = 0; i < 3; i = i + 1) begin
        //     @(posedge clk);
        //     $display("T=%0t: Cycle %0d - MAC[%0d]: ifm[%0d]*filter[%0d]=%0d*%0d, psum_out=%0d", 
        //              $time, i+4, i, 2+i, i, ifm_data[2+i], filter_data[i], psum_out);
        // end
        
        // // Output point 3: positions [4,5,6] (stride=2)
        // for (i = 0; i < 3; i = i + 1) begin
        //     @(posedge clk);
        //     $display("T=%0t: Cycle %0d - MAC[%0d]: ifm[%0d]*filter[%0d]=%0d*%0d, psum_out=%0d", 
        //              $time, i+7, i, 4+i, i, ifm_data[4+i], filter_data[i], psum_out);
        // end
        
        // // Output point 4: positions [6,7,8] (stride=2)
        // for (i = 0; i < 3; i = i + 1) begin
        //     @(posedge clk);
        //     $display("T=%0t: Cycle %0d - MAC[%0d]: ifm[%0d]*filter[%0d]=%0d*%0d, psum_out=%0d", 
        //              $time, i+10, i, 6+i, i, ifm_data[6+i], filter_data[i], psum_out);
        // end
        
        // start = 0;
        // @(posedge clk);
        // display_result(2, "3x3 convolution, stride=2");
        
        #200;
        
        //====================================================================
        // Test 3: 5x5 convolution, stride=1
        // Expected: Complete one output point every 5 clock cycles
        // First output: sum(ifm[0:4] .* filter[0:4])
        //             = 1*1 + 2*2 + 3*3 + 4*4 + 5*5 = 1+4+9+16+25 = 55
        //====================================================================
        $display("\n[Test 3] 5x5 convolution, stride=1");
        $display("Input feature map: [1,2,3,4,5,6,7]");
        $display("Convolution kernel: [1,2,3,4,5]");
        
        kernel_type = 1;  // 5x5
        stride = 0;       // stride=1
        psum_data1 = 0;
        psum_data2 = 0;
        
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        repeat(3) @(posedge clk);
        psum_data1 = 3;
        repeat(2) @(posedge clk);
        psum_data1 = 0;
        repeat(8) @(posedge clk);
        
        // // Output point 1: positions [0,1,2,3,4]
        // for (i = 0; i < 5; i = i + 1) begin
        //     @(posedge clk);
        //     $display("T=%0t: Cycle %0d - MAC[%0d]: ifm[%0d]*filter[%0d]=%0d*%0d, psum_out=%0d", 
        //              $time, i+1, i, i, i, ifm_data[i], filter_data[i], psum_out);
        // end
        
        // // Output point 2: positions [1,2,3,4,5]
        // for (i = 0; i < 5; i = i + 1) begin
        //     @(posedge clk);
        //     $display("T=%0t: Cycle %0d - MAC[%0d]: ifm[%0d]*filter[%0d]=%0d*%0d, psum_out=%0d", 
        //              $time, i+6, i, 1+i, i, ifm_data[1+i], filter_data[i], psum_out);
        // end
        
        // // Output point 3: positions [2,3,4,5,6]
        // for (i = 0; i < 5; i = i + 1) begin
        //     @(posedge clk);
        //     $display("T=%0t: Cycle %0d - MAC[%0d]: ifm[%0d]*filter[%0d]=%0d*%0d, psum_out=%0d", 
        //              $time, i+11, i, 2+i, i, ifm_data[2+i], filter_data[i], psum_out);
        // end
        
        // start = 0;
        // @(posedge clk);
        // display_result(3, "5x5 convolution, stride=1");
        
        // #100;
        
        //====================================================================
        // Test 4: 5x5 convolution, stride=2
        // Expected: Complete one output point every 5 clock cycles, but positions jump by 2
        //====================================================================
        $display("\n[Test 4] 5x5 convolution, stride=2");
        $display("Input feature map: [1,2,3,4,5,6,7,8,9]");
        $display("Convolution kernel: [1,2,3,4,5]");
        
        kernel_type = 1;  // 5x5
        stride = 1;       // stride=2
        psum_data1 = 0;
        psum_data2 = 0;
        
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        // // Output point 1: positions [0,1,2,3,4]
        // for (i = 0; i < 5; i = i + 1) begin
        //     @(posedge clk);
        //     $display("T=%0t: Cycle %0d - MAC[%0d]: ifm[%0d]*filter[%0d]=%0d*%0d, psum_out=%0d", 
        //              $time, i+1, i, i, i, ifm_data[i], filter_data[i], psum_out);
        // end
        
        // // Output point 2: positions [2,3,4,5,6] (stride=2)
        // for (i = 0; i < 5; i = i + 1) begin
        //     @(posedge clk);
        //     $display("T=%0t: Cycle %0d - MAC[%0d]: ifm[%0d]*filter[%0d]=%0d*%0d, psum_out=%0d", 
        //              $time, i+6, i, 2+i, i, ifm_data[2+i], filter_data[i], psum_out);
        // end
        
        // // Output point 3: positions [4,5,6,7,8] (stride=2)
        // for (i = 0; i < 5; i = i + 1) begin
        //     @(posedge clk);
        //     $display("T=%0t: Cycle %0d - MAC[%0d]: ifm[%0d]*filter[%0d]=%0d*%0d, psum_out=%0d", 
        //              $time, i+11, i, 4+i, i, ifm_data[4+i], filter_data[i], psum_out);
        // end
        
        // start = 0;
        // @(posedge clk);
        // display_result(4, "5x5 convolution, stride=2");
        
        #100;
        
        //====================================================================
        // Test 5: Test psum_data accumulation function
        //====================================================================
        // $display("\n[Test 5] Test partial sum (psum) accumulation");
        
        // kernel_type = 0;  // 3x3
        // stride = 0;       // stride=1
        // psum_data = 100;  // Initial partial sum
        
        // // @(posedge clk);
        // start = 1;
        
        // for (i = 0; i < 3; i = i + 1) begin
        //     @(posedge clk);
        //     $display("T=%0t: MAC[%0d]: psum_out=%0d", $time, i, psum_out);
        // end
        
        // start = 0;
        // @(posedge clk);
        // $display("Final psum_out = %0d (should = 100 + 14 = 114)", psum_out);
        // display_result(5, "Partial sum accumulation test");
        
        //====================================================================
        // Test end
        //====================================================================
        $display("\n========================================");
        $display("All tests completed!");
        $display("Time: %0t ns", $time);
        $display("========================================");
        
        #100;
        $finish;
    end
    
    // Waveform file generation
    initial begin
        $dumpfile("PE_tb.vcd");
        $dumpvars(0, PE_tb);
    end

endmodule
