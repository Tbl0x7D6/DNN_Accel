`timescale 1ns / 1ps

module Layer_tb;

    // Parameters
    parameter DATA_WIDTH = 8;
    parameter ACC_WIDTH = 26;
    
    // Clock and Reset
    logic clk;
    logic rst_n;
    
    // Configuration Inputs
    // Initialize to ensure valid values at time 0 for Layer module initialization
    logic [7:0] img_size = 5;
    logic [3:0] k_size = 3;
    logic [7:0] out_size = 5;
    logic [1:0] stride = 1;
    logic [1:0] padding = 1;

    logic [7:0] ifm_channels = 64;
    logic [7:0] ofm_channels = 32;

    logic done;
    
    // Test Data Memories
    logic signed [DATA_WIDTH-1:0] ifm_mem [0:1600-1]; 
    logic signed [DATA_WIDTH-1:0] wgt_mem [0:18432-1];
    logic signed [31:0] golden_mem [0:800-1];
    
    // DUT Instance
    Top uut (
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
    
    integer i, j, k, l, m;
    integer idx;
    
    initial begin
        // 1. Load Files
        // Adjust paths if necessary
        $readmemh("c:/Users/be/Desktop/DNN_Accel/Test_Generator/data/ifm.txt", ifm_mem);
        $readmemh("c:/Users/be/Desktop/DNN_Accel/Test_Generator/data/weights.txt", wgt_mem);
        $readmemh("c:/Users/be/Desktop/DNN_Accel/Test_Generator/data/golden.txt", golden_mem);
        
        // 2. Initialize DUT Internal Memories
        for (i = 0; i < img_size; i = i + 1) begin
            for (j = 0; j < img_size; j = j + 1) begin
                for (k = 0; k < ifm_channels / 16; k = k + 1) begin
                    logic [DATA_WIDTH*16-1:0] tmp_ifm;
                    idx = (i * img_size + j) * (ifm_channels / 16) + k;
                    for (l = 0; l < 16; l = l + 1) begin
                        tmp_ifm[l*DATA_WIDTH +: DATA_WIDTH] = ifm_mem[idx * 16 + l];
                    end
                    uut.ifm_bram_inst.xpm_memory_base_inst.mem[idx] = tmp_ifm;
                end
            end
        end
        for (i = 0; i < k_size; i = i + 1) begin
            for (j = 0; j < k_size; j = j + 1) begin
                for (k = 0; k < ifm_channels; k = k + 1) begin
                    for (l = 0; l < ofm_channels / 16; l = l + 1) begin
                        logic [DATA_WIDTH*16-1:0] tmp_weight;
                        idx = ((i * k_size + j) * ifm_channels + k) * (ofm_channels / 16) + l;
                        for (m = 0; m < 16; m = m + 1) begin
                            tmp_weight[m*DATA_WIDTH +: DATA_WIDTH] = wgt_mem[idx * 16 + m]; 
                        end
                        uut.weight_bram_inst.xpm_memory_base_inst.mem[idx] = tmp_weight;
                    end
                end
            end
        end
        for (i = 0; i < 2048; i = i + 1) begin
            uut.output_bram_inst.xpm_memory_base_inst.mem[i] = 0;
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
        for (i = 0; i < out_size; i = i + 1) begin
            for (j = 0; j < out_size; j = j + 1) begin
                for (k = 0; k < ofm_channels / 16; k = k + 1) begin
                    logic signed [ACC_WIDTH*16-1:0] dut_output;
                    idx = (i * out_size + j) * (ofm_channels / 16) + k;
                    dut_output = uut.output_bram_inst.xpm_memory_base_inst.mem[idx];
                    for (l = 0; l < 16; l = l + 1) begin
                        logic signed [ACC_WIDTH-1:0] dut_val;
                        dut_val = $signed(dut_output[l*ACC_WIDTH +: ACC_WIDTH]);
                        // if (dut_output[l*26 +: 26] !== golden_mem[idx * 16 + l]) begin
                        //     $display("Mismatch at OFM(%0d,%0d,%0d): DUT=%0d, GOLDEN=%0d",
                        //             i, j, k * 16 + l, dut_output[l*26 +: 26], golden_mem[idx * 16 + l]);
                        // end
                        if (dut_val !== golden_mem[idx * 16 + l]) begin
                            $display("Mismatch at OFM(%0d,%0d,%0d): DUT=%0d, GOLDEN=%0d",
                                    i, j, k * 16 + l, dut_val, golden_mem[idx * 16 + l]);
                        end
                    end
                    // if (dut_output !== golden_mem[idx]) begin
                    //     $display("Mismatch at OFM(%0d,%0d,%0d): DUT=%0d, GOLDEN=%0d",
                    //             i, j, k, dut_output, golden_mem[idx]);
                    // end
                end
            end
        end
        
        $finish;
    end

endmodule
