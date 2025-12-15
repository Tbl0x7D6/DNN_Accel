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
    reg [7:0] input_image [31:0][31:0];
    wire [7:0] output_buffer [7:0][31:0][31:0];

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
        .reset(reset),
        .input_image(input_image),
        .output_buffer(output_buffer)
    );

    initial begin
        integer i, j, image_file, filter_file, r, c, idx;

        image_file = $fopen("image.txt", "r");
        for (i = 0; i < 32; i = i + 1) begin
            for (j = 0; j < 32; j = j + 1) begin
                $fscanf(image_file, "%d", input_image[i][j]);
            end
        end

        filter_file = $fopen("filter.txt", "r");
        for (r = 0; r < 5; r = r + 1) begin
            reg [3071:0] temp;
            temp = 0;
            for (idx = 0; idx < 8; idx = idx + 1) begin
                for (c = 0; c < 5; c = c + 1) begin
                    reg [7:0] t;
                    $fscanf(filter_file, "%d", t);
                    temp[(idx * 5 + c) * 8 +: 8] = t;
                end
            end
            uut.filter_data.inst.native_mem_module.blk_mem_gen_v8_4_1_inst.memory[r] = temp;
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
        #600;
        $finish;
    end

endmodule
