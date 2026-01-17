`timescale 1ns / 1ps

module PostProcess #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH = 26
)(
    input logic clk,
    input logic rst_n,

    input logic [7:0] out_size,
    input logic [3:0] ofm_channel_tiles,

    input logic ReLU,
    input logic [7:0] Q,

    input  logic [ACC_WIDTH *16-1:0] input_rd_data,
    output logic [15:0]              input_rd_addr,
    // reset to zero after reading
    output logic [15:0]              input_wr_addr,
    output logic                     input_wr_en,

    output logic [DATA_WIDTH*16-1:0] output_data,
    output logic [15:0]              output_addr,
    output logic                     output_en,

    output logic done
);

    function automatic [DATA_WIDTH-1:0] quantize_relu;
        input logic signed [ACC_WIDTH-1:0] in;
        logic signed [ACC_WIDTH-1:0] scaled;
        localparam MAX_VAL = 2**(DATA_WIDTH - 1) - 1;

        begin
            scaled = in >>> Q;
            if (scaled < 0 && ReLU) begin
                quantize_relu = 0;
            end else if (scaled > MAX_VAL) begin
                quantize_relu = MAX_VAL;
            end else if (scaled < -MAX_VAL) begin
                quantize_relu = -MAX_VAL;
            end else begin
                quantize_relu = scaled[DATA_WIDTH-1:0];
            end
        end
    endfunction


    logic [7:0] ox;
    logic [7:0] oy;
    logic [3:0] tile;

    logic [15:0] addr;
    logic [15:0] prev_addr_1;
    logic [15:0] prev_addr_2;

    logic write_back_1;
    logic write_back_2;

    always_comb begin
        addr = (oy * out_size + ox) * ofm_channel_tiles + tile;

        input_rd_addr = addr;
        output_en = write_back_2;
        output_addr = prev_addr_2;

        input_wr_en = write_back_2;
        input_wr_addr = prev_addr_2;
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            {ox, oy, tile} <= 0;
            done <= 0;
            write_back_1 <= 0;
            write_back_2 <= 0;
        end else begin
            write_back_1 <= !done;
            write_back_2 <= write_back_1;
            prev_addr_1 <= addr;
            prev_addr_2 <= prev_addr_1;

            for (integer i = 0; i < 16; i++) begin
                output_data[DATA_WIDTH*i +: DATA_WIDTH]
                    <= quantize_relu(input_rd_data[ACC_WIDTH*i +: ACC_WIDTH]);
            end

            ox <= ox + 1;
            if (ox == out_size - 1) begin
                ox <= 0;
                oy <= oy + 1;
                if (oy == out_size - 1) begin
                    oy <= 0;
                    tile <= tile + 1;
                    if (tile == ofm_channel_tiles - 1) begin
                        tile <= 0;
                        done <= 1;
                    end
                end
            end
        end
    end

endmodule
