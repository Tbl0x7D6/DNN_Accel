`timescale 1ns / 1ps

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

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            aout <= '0;
            cout <= '0;
        end else begin
            aout <= ain;
            cout <= cin + ain * bin;
        end
    end

endmodule
