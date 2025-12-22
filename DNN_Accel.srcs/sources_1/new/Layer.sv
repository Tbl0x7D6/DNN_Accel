`timescale 1ns / 1ps

module Layer #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH = 26,
    parameter PE_ACC_WIDTH = 21
)(
    input logic clk,
    input logic rst_n,

    input logic [7:0] img_size,
    input logic [3:0] k_size,
    input logic [1:0] stride,
    input logic [1:0] padding,

    input logic [7:0] ifm_channels,
    input logic [7:0] ofm_channels,

    output logic done
);

    logic signed [DATA_WIDTH-1:0] ifm_in [0:15];
    logic signed [DATA_WIDTH-1:0] weight_in [0:15][0:15];
    logic signed [PE_ACC_WIDTH-1:0] psum_out [0:15];

    PE_Array #(
        .NUM_ROWS(16),
        .NUM_COLS(16),
        .DATA_WIDTH(DATA_WIDTH),
        .PE_ACC_WIDTH(PE_ACC_WIDTH)
    ) pe_array_inst (
        .clk(clk),
        .rst_n(rst_n),
        .ifm_in(ifm_in),
        .weight_in(weight_in),
        .psum_out(psum_out)
    );

    logic [7:0] out_size;
    logic [7:0] ifm_channel_tiles;
    logic [7:0] ofm_channel_tiles;
    always_comb begin
        out_size = ((img_size + 2 * padding - k_size) / stride) + 1;
        ifm_channel_tiles = (ifm_channels + 15) / 16;
        ofm_channel_tiles = (ofm_channels + 15) / 16;
    end

    logic signed [DATA_WIDTH-1:0] ifm_data    [0:31][0:31][0:127];
    logic signed [DATA_WIDTH-1:0] filter_data [0:4][0:4][0:127][0:127];
    logic signed [ACC_WIDTH-1:0]  ofm_data    [0:31][0:31][0:127];

    logic [3:0] kx, ky;
    logic [3:0] ifm_tile;
    logic [3:0] ofm_tile;
    logic [31:0] cycle_count;

    function [DATA_WIDTH-1:0] get_pad_value;
        input logic signed [7:0] ix;
        input logic signed [7:0] iy;
        input logic [7:0] ic;

        begin
            if (ix < 0 || ix >= img_size || iy < 0 || iy >= img_size) begin
                get_pad_value = 0;
            end else begin
                get_pad_value = ifm_data[iy][ix][ic];
            end
        end
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {kx, ky, ifm_tile, ofm_tile} <= 0;
            done <= 0;
            cycle_count <= 0;
            for (integer oy = 0; oy < 5; oy++) begin
                for (integer ox = 0; ox < 5; ox++) begin
                    for (integer oc = 0; oc < 16; oc++) begin
                        ofm_data[oy][ox][oc] <= 0;
                    end
                end
            end
        end else if (!done) begin
            cycle_count <= cycle_count + 1;

            // switch to next kernel position
            if (cycle_count == out_size * out_size + 16 + 16) begin
                cycle_count <= 0;

                kx <= kx + 1;
                if (kx == k_size - 1) begin
                    kx <= 0;
                    ky <= ky + 1;
                    if (ky == k_size - 1) begin
                        ky <= 0;
                        ifm_tile <= ifm_tile + 1;
                        if (ifm_tile == ifm_channel_tiles - 1) begin
                            ifm_tile <= 0;
                            ofm_tile <= ofm_tile + 1;
                            if (ofm_tile == ofm_channel_tiles - 1) begin
                                ofm_tile <= 0;
                                done <= 1;
                            end
                        end
                    end
                end
            end
            if (cycle_count == 0) begin
                for (integer ic = 0; ic < 16; ic++) begin
                    for (integer oc = 0; oc < 16; oc++) begin
                        weight_in[ic][oc] <= filter_data[ky][kx][ic + ifm_tile * 16][oc + ofm_tile * 16];
                    end
                end
            end

            // load ifm
            for (integer i = 0; i < 16; i++) begin
                automatic logic [7:0] ox = (cycle_count - i) % out_size;
                automatic logic [7:0] oy = (cycle_count - i) / out_size;
                automatic logic signed [7:0] ix = ox * stride + kx - padding;
                automatic logic signed [7:0] iy = oy * stride + ky - padding;

                ifm_in[i] <= get_pad_value(ix, iy, i + ifm_tile * 16);
            end

            // accumulate psum_out to output buffer
            if (cycle_count >= 16 + 1 &&
                cycle_count < out_size * out_size + 16 + 16 + 1
            ) begin
                for (integer i = 0; i < 16; i++) begin
                    if (cycle_count >= 16 + i + 1 && cycle_count < out_size * out_size + 16 + i + 1) begin
                        automatic logic [7:0] ox = (cycle_count - 16 - i - 1) % out_size;
                        automatic logic [7:0] oy = (cycle_count - 16 - i - 1) / out_size;
                        ofm_data[oy][ox][i + ofm_tile * 16] <= psum_out[i] + ofm_data[oy][ox][i + ofm_tile * 16];
                    end
                end
            end
        end
    end

endmodule
