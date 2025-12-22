`timescale 1ns / 1ps

module PE_Array #(
    parameter NUM_ROWS = 32,
    parameter NUM_COLS = 16,
    parameter DATA_WIDTH = 8,
    parameter PE_ACC_WIDTH = 21
)(
    input logic clk,
    input logic rst_n,

    input logic signed [DATA_WIDTH-1:0] ifm_in    [0:NUM_ROWS-1],
    input logic signed [DATA_WIDTH-1:0] weight_in [0:NUM_ROWS-1][0:NUM_COLS-1],
    // input logic signed [PE_ACC_WIDTH-1:0] psum_in [0:NUM_COLS-1],

    // output logic signed [DATA_WIDTH-1:0] ifm_out [0:NUM_ROWS-1],
    output logic signed [PE_ACC_WIDTH-1:0] psum_out [0:NUM_COLS-1]
);

    logic signed [DATA_WIDTH-1:0]   h_wires [0:NUM_COLS][0:NUM_ROWS-1]; 
    logic signed [PE_ACC_WIDTH-1:0] v_wires [0:NUM_ROWS][0:NUM_COLS-1]; 

    generate
        for (genvar r = 0; r < NUM_ROWS; r++) begin : ROW
            assign h_wires[0][r] = ifm_in[r];
            // assign ifm_out[r] = h_wires[NUM_COLS][r];

            for (genvar c = 0; c < NUM_COLS; c++) begin : COL
                if (r == 0) begin
                    // assign v_wires[0][c] = psum_in[c];
                    assign v_wires[0][c] = 0;
                end

                PE #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .PE_ACC_WIDTH(PE_ACC_WIDTH)
                ) u_pe (
                    .clk(clk),
                    .rst_n(rst_n),
                    .ain(h_wires[c][r]),
                    .bin(weight_in[r][c]),
                    .cin(v_wires[r][c]),
                    .aout(h_wires[c+1][r]),
                    .cout(v_wires[r+1][c])
                );
            end
        end

        for (genvar c = 0; c < NUM_COLS; c = c + 1) begin : OUT_COL
            assign psum_out[c] = v_wires[NUM_ROWS][c];
        end
    endgenerate

endmodule
