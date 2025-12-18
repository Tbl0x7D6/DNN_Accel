`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/13/2025 05:26:37 PM
// Design Name: 
// Module Name: controller_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module controller_tb;

    reg clk;
    reg reset;
    reg [1:0] layer_select;
    wire locked;
    wire clk_1;
    wire clk_2;

    // 应该根据 locked 生成计算单元的 reset 信号
    clk_wiz_0 mmcm_inst (
        .clk_out1(clk_1),
        .clk_out2(clk_2),
        .reset(reset),
        .locked(locked),
        .clk_in1(clk)
    );

    controller uut (
        .clk(clk_2),
        .filter_clk(clk_1),
        .fm_read_clk(clk_1),
        .fm_write_clk(clk_1),
        // .layer_select(layer_select),
        .reset(reset)
    );

    initial begin
        integer i, j, image_file, filter_file, round, r, c, idx;

        image_file = $fopen("image.txt", "r");
        for (i = 0; i < 32; i = i + 1) begin
            for (j = 0; j < 32; j = j + 1) begin
                $fscanf(image_file, "%d", uut.input_image[i][j]);
            end
        end

        filter_file = $fopen("filter.txt", "r");
        for (round = 0; round < 4; round = round + 1) begin
            for (r = 0; r < 5; r = r + 1) begin
                reg [3071:0] temp;
                temp = 0;
                for (idx = 0; idx < 8; idx = idx + 1) begin
                    for (c = 0; c < 5; c = c + 1) begin
                        reg signed [7:0] t;
                        $fscanf(filter_file, "%d", t);
                        temp[(idx * 5 + c) * 8 +: 8] = t;
                    end
                end
                uut.filter_data.xpm_memory_base_inst.mem[round * 5 + r] = temp;
            end
        end

        layer_select = 0;
    end

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset = 1;
        #15;
        reset = 0;
    end

    initial begin
        integer index, round, r, c, result_file, addr;
        #1250;

        result_file = $fopen("expected_output.txt", "r");
        for (round = 0; round < 4; round = round + 1) begin
            $display("Checking results of round %0d...", round);
            for (index = 0; index < 8; index = index + 1) begin
                for (r = 0; r < 16; r = r + 1) begin
                    for (c = 0; c < 16; c = c + 1) begin
                        reg signed [7:0] golden;
                        reg signed [7:0] result;
                        integer bram_idx;
                        integer pos;
                        $fscanf(result_file, "%d", golden);
                        addr = round * 16 + c;
                        bram_idx = index / 2;
                        pos = ((index % 2) * 16 + r) * 8;

                        case(bram_idx)
                            0: result = uut.gen_fm_bram[0].fm_bram_inst.xpm_memory_base_inst.mem[addr][pos +: 8];
                            1: result = uut.gen_fm_bram[1].fm_bram_inst.xpm_memory_base_inst.mem[addr][pos +: 8];
                            2: result = uut.gen_fm_bram[2].fm_bram_inst.xpm_memory_base_inst.mem[addr][pos +: 8];
                            3: result = uut.gen_fm_bram[3].fm_bram_inst.xpm_memory_base_inst.mem[addr][pos +: 8];
                        endcase

                        if (result !== golden) begin
                            $display("Mismatch at round %0d, index %0d, row %0d, col %0d: expected %0d, got %0d", round, index, r, c, golden, result);
                        end
                    end
                end
            end
            $display("Check complete.");
        end

        $finish;
    end

endmodule
