`timescale 1ns / 1ps

module Pooling #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH = 26
)(
    input logic clk,
    input logic rst_n,

    // 0: MAX, 1: AVG
    // for 4x4 average pooling, set Q=4 in PostProcess later
    input logic pooling_type,

    input logic [7:0] img_size,
    input logic [3:0] k_size,
    input logic [1:0] stride,
    input logic [7:0] out_size,

    input logic [3:0] ifm_channel_tiles,

    input  logic [DATA_WIDTH*16-1:0] ifm_data,
    output logic [15:0]              ifm_addr,

    input  logic [ACC_WIDTH *16-1:0] ofm_rd_data,
    output logic [15:0]              ofm_rd_addr,
    output logic [ACC_WIDTH *16-1:0] ofm_wr_data,
    output logic [15:0]              ofm_wr_addr,
    output logic                     ofm_wr_en,

    output logic done
);

    logic signed [7:0] ix;
    logic signed [7:0] iy;
    logic [7:0] ox;
    logic [7:0] oy;
    logic [3:0] tile;

    AGU pooling_agu (
        .clk(clk),
        .rst_n(rst_n),
        .next(1),
        .img_size(img_size),
        .k_size(k_size),
        .stride(stride),
        .padding(0),
        .out_size(out_size),
        .ifm_channel_tiles(ifm_channel_tiles),
        .ofm_channel_tiles(1),
        .ix(ix),
        .iy(iy),
        .ox(ox),
        .oy(oy),
        .kx(),
        .ky(),
        .ifm_tile(tile),
        .ofm_tile(),
        .is_pad(),
        .done(done)
    );

    logic write_back_1;
    logic write_back_2;
    logic [15:0] prev_output_addr_1;
    logic [15:0] prev_output_addr_2;

    logic is_first_read;

    always_comb begin
        ifm_addr    = (iy * img_size + ix) * ifm_channel_tiles + tile;
        ofm_rd_addr = (oy * out_size + ox) * ifm_channel_tiles + tile;
        ofm_wr_addr = prev_output_addr_2;
        ofm_wr_en   = write_back_2;
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            write_back_1 <= 0;
            write_back_2 <= 0;
        end else begin
            write_back_1 <= !done;
            write_back_2 <= write_back_1;
            prev_output_addr_1 <= (oy * out_size + ox) * ifm_channel_tiles + tile;
            prev_output_addr_2 <= prev_output_addr_1;

            for (integer i = 0; i < 16; i++) begin
                logic signed [ACC_WIDTH-1:0] a;
                logic signed [ACC_WIDTH-1:0] b;

                a = $signed(ofm_rd_data[ACC_WIDTH*i +: ACC_WIDTH]);

                // data forwarding
                if (out_size == 1) begin
                    if (is_first_read) begin
                        a = 0;
                    end else begin
                        a = $signed(ofm_wr_data[ACC_WIDTH*i +: ACC_WIDTH]);
                    end
                end
                is_first_read <= (ix == 0 && iy == 0);

                b = $signed(ifm_data[DATA_WIDTH*i +: DATA_WIDTH]);

                if (pooling_type == 0) begin
                    ofm_wr_data[ACC_WIDTH*i +: ACC_WIDTH] <= (a > b) ? a : b;
                end else begin
                    ofm_wr_data[ACC_WIDTH*i +: ACC_WIDTH] <= a + b;
                end
            end
        end
    end

endmodule
