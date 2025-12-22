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

    logic output_fifo_wr_en [0:15];
    logic output_fifo_rd_en [0:15];
    logic output_fifo_empty [0:15];
    logic signed [PE_ACC_WIDTH-1:0] output_fifo_din  [0:15];
    logic signed [PE_ACC_WIDTH-1:0] output_fifo_dout [0:15];

    logic can_read;

    always_comb begin
        can_read = 1;
        for (integer i = 0; i < 16; i++) begin
            if (output_fifo_empty[i]) begin
                can_read = 0;
            end
        end
        for (integer i = 0; i < 16; i++) begin
            output_fifo_rd_en[i] = can_read;
        end
    end

    generate
        for (genvar i = 0; i < 16; i++) begin : OUTPUT_FIFO_GEN
            xpm_fifo_sync # (

                .FIFO_MEMORY_TYPE          ("auto"),           //string; "auto", "block", "distributed", or "ultra";
                .ECC_MODE                  ("no_ecc"),         //string; "no_ecc" or "en_ecc";
                .FIFO_WRITE_DEPTH          (64),             //positive integer
                .WRITE_DATA_WIDTH          (PE_ACC_WIDTH),               //positive integer
                .WR_DATA_COUNT_WIDTH       (6),               //positive integer
                .PROG_FULL_THRESH          (10),               //positive integer
                .FULL_RESET_VALUE          (0),                //positive integer; 0 or 1
                .USE_ADV_FEATURES          ("0707"),           //string; "0000" to "1F1F"; 
                .READ_MODE                 ("fwft"),            //string; "std" or "fwft";
                .FIFO_READ_LATENCY         (1),                //positive integer;
                .READ_DATA_WIDTH           (PE_ACC_WIDTH),               //positive integer
                .RD_DATA_COUNT_WIDTH       (6),               //positive integer
                .PROG_EMPTY_THRESH         (10),               //positive integer
                .DOUT_RESET_VALUE          ("0"),              //string
                .WAKEUP_TIME               (0)                 //positive integer; 0 or 2;

            ) xpm_fifo_sync_inst (

                .sleep            (1'b0),
                .rst              (~rst_n),
                .wr_clk           (clk),
                .wr_en            (output_fifo_wr_en[i]),
                .din              (output_fifo_din[i]),
                .full             (),
                .overflow         (),
                .prog_full        (),
                .wr_data_count    (),
                .almost_full      (),
                .wr_ack           (),
                .wr_rst_busy      (),
                .rd_en            (output_fifo_rd_en[i]),
                .dout             (output_fifo_dout[i]),
                .empty            (output_fifo_empty[i]),
                .prog_empty       (),
                .rd_data_count    (),
                .almost_empty     (),
                .data_valid       (),
                .underflow        (),
                .rd_rst_busy      (),
                .injectsbiterr    (1'b0),
                .injectdbiterr    (1'b0),
                .sbiterr          (),
                .dbiterr          ()

            );
        end
    endgenerate

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
    logic signed [ACC_WIDTH-1:0]  ofm_data    [0:32767];

    logic [3:0] kx, ky;
    logic [3:0] ifm_tile;
    logic [3:0] ofm_tile;
    logic [31:0] pe_cycle_count;

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
            pe_cycle_count <= 0;

            // reset ofm_data, only for test
            for (integer i = 0; i < 32768; i++) begin
                ofm_data[i] <= 0;
            end
        end else if (!done) begin
            pe_cycle_count <= pe_cycle_count + 1;

            // switch to next kernel position
            if (pe_cycle_count >= out_size * out_size + 16 + 16 && !can_read) begin
                pe_cycle_count <= 0;

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
            if (pe_cycle_count == 0) begin
                for (integer ic = 0; ic < 16; ic++) begin
                    for (integer oc = 0; oc < 16; oc++) begin
                        weight_in[ic][oc] <= filter_data[ky][kx][ic + ifm_tile * 16][oc + ofm_tile * 16];
                    end
                end
            end

            // load ifm
            for (integer i = 0; i < 16; i++) begin
                automatic logic [7:0] ox = (pe_cycle_count - i) % out_size;
                automatic logic [7:0] oy = (pe_cycle_count - i) / out_size;
                automatic logic signed [7:0] ix = ox * stride + kx - padding;
                automatic logic signed [7:0] iy = oy * stride + ky - padding;

                ifm_in[i] <= get_pad_value(ix, iy, i + ifm_tile * 16);
            end

            // send psum_out to output fifo
            if (pe_cycle_count >= 16 + 1 &&
                pe_cycle_count < out_size * out_size + 16 + 16 + 1
            ) begin
                for (integer i = 0; i < 16; i++) begin
                    if (pe_cycle_count >= 16 + i + 1 && pe_cycle_count < out_size * out_size + 16 + i + 1) begin
                        output_fifo_din[i] <= psum_out[i];
                        output_fifo_wr_en[i] <= 1;
                    end else begin
                        output_fifo_wr_en[i] <= 0;
                    end
                end
            end
        end
    end

    logic [31:0] output_cycle_count;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            output_cycle_count <= 0;
            for (integer i = 0; i < 16; i++) begin
                output_fifo_rd_en[i] <= 0;
            end
        end else begin
            if (can_read) begin
                automatic logic [7:0] ox = output_cycle_count % out_size;
                automatic logic [7:0] oy = output_cycle_count / out_size;

                output_cycle_count <= output_cycle_count + 1;
                if (output_cycle_count == out_size * out_size - 1) begin
                    output_cycle_count <= 0;
                end

                for (integer i = 0; i < 16; i++) begin
                    automatic logic [15:0] addr = (oy * out_size + ox) * ofm_channels + i + ofm_tile * 16;
                    ofm_data[addr] <= output_fifo_dout[i] + ofm_data[addr];
                end
            end
        end
    end

endmodule
