`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/01/2025 05:15:51 PM
// Design Name: 
// Module Name: PE
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


module PE (
    input wire clk,
    input wire start,
    input wire kernel_type, // 0: 3x3, 1: 5x5
    input wire stride,      // 0: 1,   1: 2
    input wire [7:0] ifm_data [35:0],
    input wire [7:0] filter_data [4:0],
    input wire [20:0] psum_data,
    output reg [20:0] psum_out
);

    reg [4:0] ofm_position;
    reg [2:0] mac_count;

    reg last_start;

    always @(posedge clk) begin
        if (start && !last_start) begin
            ofm_position <= 0;
            mac_count <= 0;
        end else if (last_start) begin
            // Perform MAC operation
            psum_out <= (mac_count == 0 ? psum_data : psum_out)
                        + ifm_data[ofm_position + mac_count] * filter_data[mac_count];
            mac_count <= mac_count + 1;

            if (mac_count == (kernel_type == 0 ? 2 : 4)) begin
                mac_count <= 0;
                ofm_position <= ofm_position + (stride == 0 ? 1 : 2);
            end
        end
        last_start <= start;
    end

endmodule
