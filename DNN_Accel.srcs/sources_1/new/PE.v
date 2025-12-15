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
// Description: Processing Element for CNN Accelerator
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
    input wire kernel_type,          // 0: 3x3, 1: 5x5
    input wire use_prev_psum,        // 0: ignore psum_data, 1: use psum_data
    input wire signed [7:0] ifm_data1 [4:0],
    input wire signed [7:0] ifm_data2 [4:0],
    input wire signed [7:0] filter_data [4:0],
    input wire signed [20:0] psum_data1,
    input wire signed [20:0] psum_data2,
    output reg signed [20:0] psum_out1,
    output reg signed [20:0] psum_out2
);

    reg [2:0] mac_count;

    reg signed [20:0] psum_temp1;
    reg signed [20:0] psum_temp2;

    wire [23:0] A;
    wire [7:0] B;
    wire [31:0] P;

    xbip_dsp48_macro_0 mul (
        .CLK(clk),
        .A(A),
        .B(B),
        .P(P)
    );

    // dsp output delay is 4
    // this value denotes when we can extract the output
    // and add with psum from previous PE
    wire [2:0] dsp_out_mac_count_delay;
    assign dsp_out_mac_count_delay = (kernel_type == 0 ? 1 : 4);

    // compute two int8 multiplications concurrently
    wire [7:0] low = start ? ifm_data1[0] : ifm_data1[mac_count];
    wire [7:0] high = start ? ifm_data2[0] : ifm_data2[mac_count];
    wire [7:0] filter_byte = start ? filter_data[0] : filter_data[mac_count];

    assign A[7:0] = low[7] ? ~(low - 1) : low;
    assign A[15:8] = 8'b0;
    assign A[23:16] = high[7] ? ~(high - 1) : high;
    assign B[7:0] = filter_byte[7] ? ~(filter_byte - 1) : filter_byte;

    wire sign_low = low[7] ^ filter_byte[7];
    wire sign_high = high[7] ^ filter_byte[7];

    reg sign_low_queue [3:0];
    reg sign_high_queue [3:0];

    wire signed [15:0] low_result = sign_low_queue[3] ? ~P[15:0] + 1 : P[15:0];
    wire signed [15:0] high_result = sign_high_queue[3] ? ~P[31:16] + 1 : P[31:16];

    always @(posedge clk) begin
        // FSM
        if (start) begin
            mac_count <= 1;
        end else begin
            mac_count <= mac_count + 1;
            if (mac_count == (kernel_type == 0 ? 2 : 4)) begin
                mac_count <= 0;
            end
        end

        for (integer i = 3; i > 0; i = i - 1) begin
            sign_low_queue[i] <= sign_low_queue[i-1];
            sign_high_queue[i] <= sign_high_queue[i-1];
        end

        sign_low_queue[0] <= sign_low;
        sign_high_queue[0] <= sign_high;

        // make sure psum_out is available in several cycles for next PE
        if (mac_count == dsp_out_mac_count_delay) begin
            psum_temp1 <= (use_prev_psum ? psum_data1 : 21'sd0) + low_result;
            psum_temp2 <= (use_prev_psum ? psum_data2 : 21'sd0) + high_result;
        end else if (mac_count + 1 == dsp_out_mac_count_delay) begin
            psum_out1 <= psum_temp1 + low_result;
            psum_out2 <= psum_temp2 + high_result;
        end else begin
            psum_temp1 <= psum_temp1 + low_result;
            psum_temp2 <= psum_temp2 + high_result;
        end
    end

endmodule
