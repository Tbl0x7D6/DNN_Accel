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
    reg [7:0] filter_buffer [127:0][4:0];
    reg [7:0] input_image [31:0][31:0];
    wire [7:0] output_buffer [7:0][31:0][31:0];

    controller uut (
        .clk(clk),
        .reset(reset),
        .filter_buffer(filter_buffer),
        .input_image(input_image),
        .output_buffer(output_buffer)
    );

    initial begin
        integer i, j, image_file;

        image_file = $fopen("image.txt", "r");
        for (i = 0; i < 32; i = i + 1) begin
            for (j = 0; j < 32; j = j + 1) begin
                $fscanf(image_file, "%d", input_image[i][j]);
            end
        end
    end

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        integer r, idx, c, filter_file;

        reset = 1;
        #15;
        reset = 0;

        filter_file = $fopen("filter.txt", "r");
        @(posedge clk);
        for (r = 0; r < 5; r = r + 1) begin
            for (idx = 0; idx < 8; idx = idx + 1) begin
                for (c = 0; c < 5; c = c + 1) begin
                    $fscanf(filter_file, "%d", filter_buffer[idx][c]);
                end
            end
            repeat(5) @(posedge clk);
        end
    end

    initial begin
        #3000;
        $finish;
    end

endmodule
