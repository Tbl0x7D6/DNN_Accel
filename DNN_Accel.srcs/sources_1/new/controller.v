`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/13/2025 02:30:35 AM
// Design Name: 
// Module Name: controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module controller (
    input wire clk,
    input wire reset,
    // these 3 lines are just for convenient testing
    // will consume lots of time in synthesis
    input wire [7:0] filter_buffer [127:0][4:0],
    input wire [7:0] input_image [31:0][31:0],
    output reg [7:0] output_buffer [7:0][31:0][31:0]
);

    // PE array size
    localparam HEIGHT = 24;
    localparam WIDTH = 32;

    // PE tile size
    localparam MAX_PE_TILE_HEIGHT = 5;
    localparam MAX_PE_TILE_WIDTH = 16;
    localparam PE_TILE_HEIGHT = 5;
    localparam PE_TILE_WIDTH = 16;

    // same value for all PEs
    localparam KERNEL_TYPE = 1;
    localparam STRIDE_TYPE = 0;

    localparam IFM_SIZE = 32;

    // start signals for each row of a PE tile
    reg start [MAX_PE_TILE_HEIGHT-1:0];

    // original layout
    // reg [7:0] input_image [31:0][31:0];

    // data buffer of bram, can update every KERNEL_SIZE cycles
    // reg [7:0] filter_buffer [(HEIGHT/3 * WIDTH/2) - 1:0][4:0];

    // output data buffer
    // currently only work for conv1 output (8x32x32)
    // reg [7:0] output_buffer [7:0][31:0][31:0];

    // same ifm data for all PEs
    reg [7:0] pe_ifm_data1 [MAX_PE_TILE_HEIGHT-1:0][MAX_PE_TILE_WIDTH-1:0][4:0];
    reg [7:0] pe_ifm_data2 [MAX_PE_TILE_HEIGHT-1:0][MAX_PE_TILE_WIDTH-1:0][4:0];

    // same filter data for each 2 PEs
    reg [7:0] pe_filter_data [HEIGHT-1:0][WIDTH/2-1:0][4:0];

    // base address for ifm / ofm
    // wire [15:0] ifm_base_addr = 0;
    // wire [15:0] ofm_base_addr = 1;

    reg [15:0] cycle_count;
    reg [15:0] load_count;
    reg [15:0] store_count;

    // PE output signals for pipeline connections
    wire [20:0] psum_out1 [HEIGHT-1:0][WIDTH-1:0];
    wire [20:0] psum_out2 [HEIGHT-1:0][WIDTH-1:0];
    wire [20:0] psum_in1 [HEIGHT-1:0][WIDTH-1:0];
    wire [20:0] psum_in2 [HEIGHT-1:0][WIDTH-1:0];

    // PE array
    genvar i, j;
    generate
        for (i = 0; i < HEIGHT; i = i + 1) begin : gen_row
            for (j = 0; j < WIDTH; j = j + 1) begin : gen_col
                if (i == 0) begin : first_row
                    assign psum_in1[i][j] = 32'b0;
                    assign psum_in2[i][j] = 32'b0;
                end else begin : other_rows
                    assign psum_in1[i][j] = psum_out1[i-1][j];
                    assign psum_in2[i][j] = psum_out2[i-1][j];
                end

                PE pe_inst (
                    .clk(clk),
                    .kernel_type(KERNEL_TYPE),
                    .start(start[i % PE_TILE_HEIGHT]),
                    .use_prev_psum(i % (KERNEL_TYPE ? 5 : 3) == 0 ? 0 : 1),
                    .filter_data(pe_filter_data[i][j/2]),
                    .ifm_data1(pe_ifm_data1[i % PE_TILE_HEIGHT][j % PE_TILE_WIDTH]),
                    .ifm_data2(pe_ifm_data2[i % PE_TILE_HEIGHT][j % PE_TILE_WIDTH]),
                    .psum_data1(psum_in1[i][j]),
                    .psum_data2(psum_in2[i][j]),
                    .psum_out1(psum_out1[i][j]),
                    .psum_out2(psum_out2[i][j])
                );
            end
        end
    endgenerate

    function [7:0] img_after_padding;
        input integer r;
        input integer c;

        begin
            automatic integer m = KERNEL_TYPE ? 2 : 1;
            automatic integer M = IFM_SIZE + m - 1;
            if (r < m || r > M || c < m || c > M) begin
                img_after_padding = 0;
            end else begin
                img_after_padding = input_image[r - m][c - m];
            end
        end
    endfunction

    always @(posedge clk) begin
        if (reset) begin
            cycle_count <= 0;
            load_count <= 0;
            store_count <= 0;
            for (integer i = 0; i < MAX_PE_TILE_HEIGHT; i = i + 1) begin
                start[i] <= 0;
            end
        end else begin
            cycle_count <= cycle_count + 1;

            // load ifm and filter data to PEs at the right time
            if ((cycle_count + 1) % (KERNEL_TYPE ? 5 : 3) == 0) begin
                load_count <= load_count + 1;

                // set pe ifm data according to original image
                for (integer i = 0; i < MAX_PE_TILE_HEIGHT; i = i + 1) begin
                    for (integer j = 0; j < MAX_PE_TILE_WIDTH; j = j + 1) begin
                        if (i == 0 || j == PE_TILE_WIDTH-1) begin
                            automatic integer r1 = i + j;
                            automatic integer r2 = r1 + PE_TILE_WIDTH;
                            automatic integer c = load_count - i;
                            for (integer k = 0; k < 5; k = k + 1) begin
                                pe_ifm_data1[i][j][k] <= img_after_padding(r1, c + k);
                                pe_ifm_data2[i][j][k] <= img_after_padding(r2, c + k);
                            end
                        end else if (i < PE_TILE_HEIGHT && j < PE_TILE_WIDTH) begin
                            pe_ifm_data1[i][j] <= pe_ifm_data1[i-1][j+1];
                            pe_ifm_data2[i][j] <= pe_ifm_data2[i-1][j+1];
                        end
                    end
                end

                // set pe filter data according to filter buffer
                if (load_count < (KERNEL_TYPE ? 5 : 3)) begin
                    for (integer i = 0; i < HEIGHT; i = i + 1) begin
                        for (integer j = 0; j < WIDTH; j = j + 2) begin
                            automatic integer index = i / (KERNEL_TYPE ? 5 : 3) * (WIDTH / PE_TILE_WIDTH)
                                                    + j / PE_TILE_WIDTH;
                            if (i % (KERNEL_TYPE ? 5 : 3) == load_count % (KERNEL_TYPE ? 5 : 3)) begin
                                pe_filter_data[i][j/2] <= filter_buffer[index];
                            end
                        end
                    end
                end
            end

            // store output psum to output buffer at the right time
            if (cycle_count > ((KERNEL_TYPE ? 5 : 3) - 1 + 29) && (cycle_count - ((KERNEL_TYPE ? 5 : 3) - 1 + 29)) % 5 == 1) begin
                store_count <= store_count + 1;

                for (integer i = 0; i < HEIGHT; i = i + 1) begin
                    if ((i + 1) % (KERNEL_TYPE ? 5 : 3) == 0) begin
                        for (integer j = 0; j < WIDTH; j = j + 1) begin
                            automatic integer img_r = i / (KERNEL_TYPE ? 5 : 3);
                            automatic integer img_c = j / PE_TILE_WIDTH;
                            automatic integer img_index = img_r * (WIDTH / PE_TILE_WIDTH) + img_c;
                            automatic integer r = j % PE_TILE_WIDTH;

                            output_buffer[img_index][r][store_count] <= psum_out1[i][j];
                            output_buffer[img_index][r + PE_TILE_WIDTH][store_count] <= psum_out2[i][j];
                        end
                    end
                end
            end

            // generate start signals
            for (integer i = 0; i < MAX_PE_TILE_HEIGHT; i = i + 1) begin
                if (cycle_count == (i + 1) * (KERNEL_TYPE ? 5 : 3) - 1) begin
                    start[i] <= 1;
                end else begin
                    start[i] <= 0;
                end
            end
        end
    end

endmodule
