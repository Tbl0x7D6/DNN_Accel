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

    reg [5:0] pe_tile_height;
    reg [5:0] pe_tile_width;

    // same value for all PEs
    reg kernel_type;
    reg stride;
    reg [3:0] kernel_size;
    reg [5:0] ifm_size;

    // start signals for each row of a PE tile
    reg start [MAX_PE_TILE_HEIGHT-1:0];

    // use previous psum signals for each row of a PE tile
    reg use_prev_psum [MAX_PE_TILE_HEIGHT-1:0];

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
                    .kernel_type(kernel_type),
                    .start(start[i % pe_tile_height]),
                    .use_prev_psum(use_prev_psum[i % pe_tile_height]),
                    .filter_data(pe_filter_data[i][j/2]),
                    .ifm_data1(pe_ifm_data1[i % pe_tile_height][j % pe_tile_width]),
                    .ifm_data2(pe_ifm_data2[i % pe_tile_height][j % pe_tile_width]),
                    .psum_data1(psum_in1[i][j]),
                    .psum_data2(psum_in2[i][j]),
                    .psum_out1(psum_out1[i][j]),
                    .psum_out2(psum_out2[i][j])
                );
            end
        end
    endgenerate

    // used to test conv1
    always @(posedge clk) begin
        kernel_type <= 1;
        stride <= 0;
        kernel_size <= 5;      // actually it's always equal to pe_tile_height
        ifm_size <= 32;
        pe_tile_height <= MAX_PE_TILE_HEIGHT;
        pe_tile_width <= MAX_PE_TILE_WIDTH;
        for (integer i = 0; i < HEIGHT; i = i + 1) begin
            use_prev_psum[i] <= (i % 5 == 0 ? 0 : 1);
        end
    end

    function [7:0] img_after_padding;
        input integer r;
        input integer c;

        begin
            automatic integer m = (kernel_size - 1) / 2;
            automatic integer M = ifm_size + m - 1;
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
            if ((cycle_count + 1) % kernel_size == 0) begin
                load_count <= load_count + 1;

                // set pe ifm data according to original image
                for (integer i = 0; i < MAX_PE_TILE_HEIGHT; i = i + 1) begin
                    for (integer j = 0; j < MAX_PE_TILE_WIDTH; j = j + 1) begin
                        if (i == 0 || j == pe_tile_width-1) begin
                            automatic integer r1 = i + j;
                            automatic integer r2 = r1 + pe_tile_width;
                            automatic integer c = load_count - i;
                            for (integer k = 0; k < 5; k = k + 1) begin
                                pe_ifm_data1[i][j][k] <= img_after_padding(r1, c + k);
                                pe_ifm_data2[i][j][k] <= img_after_padding(r2, c + k);
                            end
                        end else begin
                            pe_ifm_data1[i][j] <= pe_ifm_data1[i-1][j+1];
                            pe_ifm_data2[i][j] <= pe_ifm_data2[i-1][j+1];
                        end
                    end
                end

                // set pe filter data according to filter buffer
                if (load_count < kernel_size) begin
                    for (integer i = 0; i < HEIGHT; i = i + 1) begin
                        for (integer j = 0; j < WIDTH; j = j + 2) begin
                            automatic integer index = i / kernel_size * (WIDTH / pe_tile_width)
                                                    + j / pe_tile_width;
                            if (i % kernel_size == load_count % kernel_size) begin
                                pe_filter_data[i][j/2] <= filter_buffer[index];
                            end
                        end
                    end
                end
            end

            // store output psum to output buffer at the right time
            if (cycle_count > (kernel_size - 1 + 29) && (cycle_count - (kernel_size - 1 + 29)) % 5 == 1) begin
                store_count <= store_count + 1;

                for (integer i = 0; i < HEIGHT; i = i + 1) begin
                    if ((i + 1) % kernel_size == 0) begin
                        for (integer j = 0; j < WIDTH; j = j + 1) begin
                            automatic integer img_r = i / kernel_size;
                            automatic integer img_c = j / pe_tile_width;
                            automatic integer img_index = img_r * (WIDTH / pe_tile_width) + img_c;
                            automatic integer r = j % pe_tile_width;

                            output_buffer[img_index][r][store_count] <= psum_out1[i][j];
                            output_buffer[img_index][r + pe_tile_width][store_count] <= psum_out2[i][j];
                        end
                    end
                end
            end

            // generate start signals
            for (integer i = 0; i < MAX_PE_TILE_HEIGHT; i = i + 1) begin
                if (cycle_count == (i + 1) * kernel_size - 1) begin
                    start[i] <= 1;
                end else begin
                    start[i] <= 0;
                end
            end
        end
    end

endmodule
