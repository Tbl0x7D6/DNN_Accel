`timescale 1ns / 1ps

module AGU(
    input logic clk,
    input logic rst_n,

    input logic next,

    input logic [7:0] img_size,
    input logic [3:0] k_size,
    input logic [1:0] stride,
    input logic [1:0] padding,
    input logic [7:0] out_size,

    input logic [3:0] ifm_channel_tiles,
    input logic [3:0] ofm_channel_tiles,

    output logic signed [7:0] ix,
    output logic signed [7:0] iy,
    output logic [7:0] ox,
    output logic [7:0] oy,
    output logic [3:0] kx,
    output logic [3:0] ky,
    output logic [3:0] ifm_tile,
    output logic [3:0] ofm_tile,

    output logic is_pad,

    output logic done
);

    logic [31:0] count;

    always_comb begin
        ix = ox * stride + kx - padding;
        iy = oy * stride + ky - padding;
        if (ix < 0 || ix >= img_size || iy < 0 || iy >= img_size) begin
            is_pad = 1;
        end else begin
            is_pad = 0;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            count <= 0;
            {ox, oy, kx, ky, ifm_tile, ofm_tile} <= 0;
            done <= 0;
        end else if (next) begin
            count <= count + 1;
            ox <= ox + 1;
            if (ox == out_size - 1) begin
                ox <= 0;
                oy <= oy + 1;
                if (oy == out_size - 1) begin
                    oy <= 0;
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
            end
        end
    end
endmodule
