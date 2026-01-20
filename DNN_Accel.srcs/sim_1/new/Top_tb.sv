`timescale 1ns / 1ps

module Top_tb;

    parameter DATA_WIDTH = 8;
    parameter ACC_WIDTH = 26;
    parameter PE_ACC_WIDTH = 21;

    logic clk;
    logic rst_n;
    logic start;
    logic done;

    Top dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .done(done)
    );

    logic signed [DATA_WIDTH-1:0] ifm_mem [0:2048*16-1]; 
    logic signed [DATA_WIDTH-1:0] wgt_mem [0:16384*16-1];
    logic signed [7:0] golden_mem [0:2048*16-1];

    logic [7:0] img_size;
    logic [7:0] out_size;
    logic [3:0] ifm_channel_tiles;
    logic [3:0] ofm_channel_tiles;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $readmemh("c:/Users/be/Desktop/DNN_Accel/Test_Generator/data/ifm.txt", ifm_mem);
        $readmemh("c:/Users/be/Desktop/DNN_Accel/Test_Generator/data/weights.txt", wgt_mem);
        $readmemh("c:/Users/be/Desktop/DNN_Accel/Test_Generator/data/golden_5.txt", golden_mem);

        img_size = 32;
        ifm_channel_tiles = 1;

        for (integer idx = 0; idx < img_size * img_size * ifm_channel_tiles; idx++) begin
            logic [DATA_WIDTH*16-1:0] tmp_ifm;
            for (integer l = 0; l < 16; l = l + 1) begin
                tmp_ifm[l*DATA_WIDTH +: DATA_WIDTH] = ifm_mem[idx * 16 + l];
            end
            dut.ifm_bram_inst.xpm_memory_base_inst.mem[idx] = tmp_ifm;
        end
        for (integer i = 0; i < 8992; i++) begin
            logic [DATA_WIDTH*16-1:0] tmp_weight;
            for (integer j = 0; j < 16; j = j + 1) begin
                tmp_weight[j*DATA_WIDTH +: DATA_WIDTH] = wgt_mem[i * 16 + j];
            end
            dut.weight_bram_inst.xpm_memory_base_inst.mem[i] = tmp_weight;
        end

        dut.instruction_bram_inst.xpm_memory_base_inst.mem[0] = 64'h0109000020562012;
        dut.instruction_bram_inst.xpm_memory_base_inst.mem[1] = 64'h1000000020281022;
        dut.instruction_bram_inst.xpm_memory_base_inst.mem[2] = 64'h0108032010351024;
        dut.instruction_bram_inst.xpm_memory_base_inst.mem[3] = 64'h010807A010390844;
        dut.instruction_bram_inst.xpm_memory_base_inst.mem[4] = 64'h010810A008390448;
        dut.instruction_bram_inst.xpm_memory_base_inst.mem[5] = 64'h3004000004440188;
        dut.instruction_bram_inst.xpm_memory_base_inst.mem[6] = 64'h000622A001140181;
        dut.instruction_bram_inst.xpm_memory_base_inst.mem[7] = 64'hFFFFFFFFFFFFFFFF;


        rst_n = 0;
        start = 0;
        #100;
        rst_n = 1;
        #200;
        start = 1;
        wait(done);
        #10;
        start = 0;
        #200;

        $display("Simulation Finished.");

        out_size = 1;
        ofm_channel_tiles = 1;

        for (integer idx = 0; idx < out_size * out_size * ofm_channel_tiles; idx++) begin
            integer i = (idx / out_size) % out_size;
            integer j = idx % out_size;
            integer k = idx / (out_size * out_size);

            logic signed [127:0] dut_output;
            dut_output = dut.ifm_bram_inst.xpm_memory_base_inst.mem[idx];
            for (integer l = 0; l < 16; l = l + 1) begin
                logic signed [7:0] dut_val;
                dut_val = $signed(dut_output[l*8 +: 8]);
                $display("Checking OFM(%0d,%0d,%0d): DUT=%0d, GOLDEN=%0d",
                            i, j, k * 16 + l, dut_val, golden_mem[idx * 16 + l]);
                if (dut_val !== golden_mem[idx * 16 + l]) begin
                    $display("Mismatch at OFM(%0d,%0d,%0d): DUT=%0d, GOLDEN=%0d",
                            i, j, k * 16 + l, dut_val, golden_mem[idx * 16 + l]);
                    $finish;
                end
            end
        end

        $finish;
    end

endmodule
