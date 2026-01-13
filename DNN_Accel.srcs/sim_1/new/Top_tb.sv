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
    logic [7:0] ifm_channels;
    logic [7:0] ofm_channels;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    integer i, j, k, l, m;
    integer idx;

    initial begin
        $readmemh("c:/Users/be/Desktop/DNN_Accel/Test_Generator/data/ifm.txt", ifm_mem);
        $readmemh("c:/Users/be/Desktop/DNN_Accel/Test_Generator/data/weights.txt", wgt_mem);
        $readmemh("c:/Users/be/Desktop/DNN_Accel/Test_Generator/data/golden_5.txt", golden_mem);

        img_size = 32;
        ifm_channels = 16;

        for (i = 0; i < img_size; i = i + 1) begin
            for (j = 0; j < img_size; j = j + 1) begin
                for (k = 0; k < ifm_channels / 16; k = k + 1) begin
                    logic [DATA_WIDTH*16-1:0] tmp_ifm;
                    idx = (i * img_size + j) * (ifm_channels / 16) + k;
                    for (l = 0; l < 16; l = l + 1) begin
                        tmp_ifm[l*DATA_WIDTH +: DATA_WIDTH] = ifm_mem[idx * 16 + l];
                    end
                    dut.ifm_bram_inst.xpm_memory_base_inst.mem[idx] = tmp_ifm;
                end
            end
        end
        for (i = 0; i < 8992; i++) begin
            logic [DATA_WIDTH*16-1:0] tmp_weight;
            for (j = 0; j < 16; j = j + 1) begin
                tmp_weight[j*DATA_WIDTH +: DATA_WIDTH] = wgt_mem[i * 16 + j];
            end
            dut.weight_bram_inst.xpm_memory_base_inst.mem[i] = tmp_weight;
        end

        dut.instruction_bram_inst.xpm_memory_base_inst.mem[0] = 64'h0109000020561020;
        dut.instruction_bram_inst.xpm_memory_base_inst.mem[1] = 64'h1000000020282020;
        dut.instruction_bram_inst.xpm_memory_base_inst.mem[2] = 64'h0108032010352040;
        dut.instruction_bram_inst.xpm_memory_base_inst.mem[3] = 64'h010807A010394040;
        dut.instruction_bram_inst.xpm_memory_base_inst.mem[4] = 64'h010810A008394080;
        dut.instruction_bram_inst.xpm_memory_base_inst.mem[5] = 64'h3004000004448080;
        dut.instruction_bram_inst.xpm_memory_base_inst.mem[6] = 64'h000622A001148010;
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
        ofm_channels = 16;

        for (i = 0; i < out_size; i = i + 1) begin
            for (j = 0; j < out_size; j = j + 1) begin
                for (k = 0; k < ofm_channels / 16; k = k + 1) begin
                    logic signed [127:0] dut_output;
                    idx = (i * out_size + j) * (ofm_channels / 16) + k;
                    dut_output = dut.ifm_bram_inst.xpm_memory_base_inst.mem[idx];
                    for (l = 0; l < 16; l = l + 1) begin
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
            end
        end

        $finish;
    end

endmodule
