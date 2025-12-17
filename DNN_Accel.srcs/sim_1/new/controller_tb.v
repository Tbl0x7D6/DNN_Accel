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
                uut.filter_data.inst.native_mem_module.blk_mem_gen_v8_4_1_inst.memory[round * 5 + r] = temp;
            end
        end
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
        integer index, round, r, c, result_file;
        #555;

        result_file = $fopen("expected_output.txt", "r");
        for (round = 0; round < 4; round = round + 1) begin
            $display("Checking results of round %0d...", round);
            for (index = 0; index < 8; index = index + 1) begin
                for (r = 0; r < 16; r = r + 1) begin
                    for (c = 0; c < 16; c = c + 1) begin
                        reg signed [7:0] tmp;
                        $fscanf(result_file, "%d", tmp);
                        if (uut.output_buffer[index * 256 + r * 16 + c] != tmp) begin
                            $display("Mismatch at index %0d, row %0d, col %0d: expected %0d, got %0d", index, r, c, tmp, uut.output_buffer[index * 256 + r * 16 + c]);
                        end
                    end
                end
            end
            $display("Check complete.");
            #180;
        end

        $finish;
    end

endmodule
