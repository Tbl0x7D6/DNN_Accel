`timescale 1ns / 1ps

module AGU(
    input logic clk,
    input logic rst_n,

    input logic next,
    input logic is_conv,

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

    output logic [15:0] ifm_addr,
    output logic [15:0] ofm_addr,

    output logic is_pad,

    output logic done
);

    logic [31:0] count;
    logic [15:0] s1, s2, s3, s4, s5, s6;

    always_comb begin
        if (ix < 0 || ix >= img_size || iy < 0 || iy >= img_size) begin
            is_pad = 1;
        end else begin
            is_pad = 0;
        end
    end

    always_ff @(posedge clk) begin
        logic [7:0]  next_ix;
        logic [7:0]  next_iy;
        logic [15:0] next_ifm_addr;
        logic [15:0] next_ofm_addr;

        if (!rst_n) begin
            count <= 0;
            {ox, oy, kx, ky, ifm_tile, ofm_tile} <= 0;
            next_ix = -signed'({1'b0, padding});
            next_iy = -signed'({1'b0, padding});
            next_ifm_addr = -padding * (img_size + 1);
            next_ofm_addr = 0;
            done <= 0;

            s1 <= (img_size - out_size) * stride;
            s2 <= 1 - out_size * img_size * stride;
            s3 <= out_size * out_size;
            s4 <= img_size - k_size;
            s5 <= (img_size - k_size) * img_size;
            s6 <= img_size * img_size * ifm_channel_tiles;
        end else if (next) begin
            count <= count + 1;

            next_ifm_addr = ifm_addr + stride;
            next_ofm_addr = ofm_addr + 1;
            if (ox != out_size - 1) begin
                ox <= ox + 1;

                next_ix = ix + signed'({1'b0, stride});
                next_iy = iy;
            end else begin
                ox <= 0;

                next_ifm_addr = next_ifm_addr + s1;
                if (oy != out_size - 1) begin
                    oy <= oy + 1;

                    next_ix = signed'({1'b0, kx}) - signed'({1'b0, padding});
                    next_iy = iy + signed'({1'b0, stride});
                end else begin
                    oy <= 0;

                    next_ifm_addr = next_ifm_addr + s2;
                    next_ofm_addr = next_ofm_addr - s3;
                    if (kx != k_size - 1) begin
                        kx <= kx + 1;

                        next_ix = signed'({1'b0, kx}) + 1 - signed'({1'b0, padding});
                        next_iy = signed'({1'b0, ky}) - signed'({1'b0, padding});
                    end else begin
                        kx <= 0;

                        next_ifm_addr = next_ifm_addr + s4;
                        if (ky != k_size - 1) begin
                            ky <= ky + 1;

                            next_ix = -signed'({1'b0, padding});
                            next_iy = signed'({1'b0, ky}) + 1 - signed'({1'b0, padding});
                        end else begin
                            ky <= 0;

                            next_ix = -signed'({1'b0, padding});
                            next_iy = -signed'({1'b0, padding});

                            next_ifm_addr = next_ifm_addr + s5;
                            if (!is_conv) begin
                                next_ofm_addr = next_ofm_addr + s3;
                            end

                            if (ifm_tile != ifm_channel_tiles - 1) begin
                                ifm_tile <= ifm_tile + 1;
                            end else begin
                                ifm_tile <= 0;

                                next_ifm_addr = next_ifm_addr - s6;
                                if (ofm_tile != ofm_channel_tiles - 1) begin
                                    ofm_tile <= ofm_tile + 1;

                                    next_ofm_addr = next_ofm_addr + s3;
                                end else begin
                                    ofm_tile <= 0;
                                    done <= 1;
                                end
                            end
                        end
                    end
                end
            end
        end

        ix <= next_ix;
        iy <= next_iy;
        ifm_addr <= next_ifm_addr;
        ofm_addr <= next_ofm_addr;
    end
endmodule
