`timescale 1ns / 1ps

(* use_dsp = "yes" *)
module PE #(
    parameter DATA_WIDTH = 8,
    parameter PE_ACC_WIDTH = 21
)(
    input  logic clk,
    input  logic rst_n,

    input  logic signed [DATA_WIDTH-1:0]   ain,
    input  logic signed [DATA_WIDTH-1:0]   bin,
    input  logic signed [PE_ACC_WIDTH-1:0] cin,

    output logic signed [DATA_WIDTH-1:0]   aout,
    output logic signed [PE_ACC_WIDTH-1:0] cout
);

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            aout <= '0;
            cout <= '0;
        end else begin
            aout <= ain;
            cout <= cin + ain * bin;
        end
    end

endmodule
