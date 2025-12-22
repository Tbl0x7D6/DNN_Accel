`timescale 1ns / 1ps

module Layer_tb;

    // Parameters
    parameter DATA_WIDTH = 8;
    
    // Clock and Reset
    logic clk;
    logic rst_n;
    
    // Configuration Inputs
    // Initialize to ensure valid values at time 0 for Layer module initialization
    logic [7:0] img_size = 5;
    logic [3:0] k_size = 3;
    logic [1:0] stride = 1;
    logic [1:0] padding = 1;

    logic [7:0] ifm_channels = 64;
    logic [7:0] ofm_channels = 32;

    logic done;
    
    // Test Data Memories
    // IFM: 5x5x64 in file
    logic signed [DATA_WIDTH-1:0] ifm_mem [0:1600-1]; 
    
    // Weights: 3x3x64x32
    logic signed [DATA_WIDTH-1:0] wgt_mem [0:18432-1];
    
    // Golden: 5x5x32 (32-bit words in file)
    logic [31:0] golden_mem [0:800-1];
    
    // DUT Instance
    Layer uut (
        .clk(clk),
        .rst_n(rst_n),
        .img_size(img_size),
        .k_size(k_size),
        .stride(stride),
        .padding(padding),
        .ifm_channels(ifm_channels),
        .ofm_channels(ofm_channels),
        .done(done)
    );
    
    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    integer i, j, k_idx, l;
    integer idx;
    
    initial begin
        // 1. Load Files
        // Adjust paths if necessary
        $readmemh("c:/Users/be/Desktop/DNN_Accel/Test_Generator/data/ifm.txt", ifm_mem);
        $readmemh("c:/Users/be/Desktop/DNN_Accel/Test_Generator/data/weights.txt", wgt_mem);
        $readmemh("c:/Users/be/Desktop/DNN_Accel/Test_Generator/data/golden.txt", golden_mem);
        
        // 2. Initialize DUT Internal Memories
        // Layer.sv has internal arrays [0:4][0:4] (5x5).
        // We copy the top-left 5x5 crop from the 8x8 loaded data.
        
        // Initialize IFM (5x5x32)
        for (i = 0; i < 5; i = i + 1) begin
            for (j = 0; j < 5; j = j + 1) begin
                for (k_idx = 0; k_idx < 64; k_idx = k_idx + 1) begin
                    // ifm_mem is row-major 8x8
                    idx = (i * 5 + j) * 64 + k_idx;
                    uut.ifm_data[i][j][k_idx] = ifm_mem[idx];
                end
            end
        end
        
        // Initialize Weights (3x3x32x16)
        // wgt_mem is flattened [KH][KW][IC][OC]
        for (i = 0; i < 3; i = i + 1) begin
            for (j = 0; j < 3; j = j + 1) begin
                for (k_idx = 0; k_idx < 64; k_idx = k_idx + 1) begin
                    for (l = 0; l < 32; l = l + 1) begin
                        idx = ((i * 3 + j) * 64 + k_idx) * 32 + l;
                        uut.filter_data[i][j][k_idx][l] = wgt_mem[idx];
                    end
                end
            end
        end
        
        // 3. Reset Sequence
        rst_n = 0;
        #100;
        rst_n = 1;
        
        // 4. Wait for Completion
        wait(done);
        #100;
        
        $display("Simulation Finished.");
        
        // 5. Check Results
        for (i = 0; i < 5; i = i + 1) begin
            for (j = 0; j < 5; j = j + 1) begin
                for (k_idx = 0; k_idx < 32; k_idx = k_idx + 1) begin
                    logic [31:0] dut_output;
                    idx = (i * 5 + j) * 32 + k_idx;
                    // dut_output = uut.ofm_data[i][j][k_idx];
                    dut_output = uut.ofm_data[idx];
                    if (dut_output !== golden_mem[idx]) begin
                        $display("Mismatch at OFM(%0d,%0d,%0d): DUT=%0d, GOLDEN=%0d",
                                i, j, k_idx, dut_output, golden_mem[idx]);
                    end
                end
            end
        end
        
        $finish;
    end

endmodule
