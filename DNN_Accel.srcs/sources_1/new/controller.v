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
    input wire filter_clk,
    input wire reset
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
    localparam OFM_SIZE = 32;

    // quantization, Q = Q_in + Q_w - Q_out
    // psum_out should be shifted right by Q bits
    localparam Q = 9;

    // start signals for each row of a PE tile
    reg start [MAX_PE_TILE_HEIGHT-1:0];

    // original layout
    reg signed [7:0] input_image [31:0][31:0];

    // data buffer of bram, can update every KERNEL_SIZE cycles
    reg signed [7:0] filter_buffer [HEIGHT-1:0][WIDTH/2-1:0][4:0];

    // before write back to bram
    reg signed [7:0] output_buffer [8191:0];

    // same ifm data for all PEs
    reg signed [7:0] pe_ifm_data1 [MAX_PE_TILE_HEIGHT-1:0][MAX_PE_TILE_WIDTH-1:0][4:0];
    reg signed [7:0] pe_ifm_data2 [MAX_PE_TILE_HEIGHT-1:0][MAX_PE_TILE_WIDTH-1:0][4:0];

    // same filter data for each 2 PEs
    reg signed [7:0] pe_filter_data [HEIGHT-1:0][WIDTH/2-1:0][4:0];

    // cache ofm data from PE tiles
    reg signed [7:0] pe_output_data [8191:0];

    // PE output signals for pipeline connections
    wire signed [20:0] psum_out1 [HEIGHT-1:0][WIDTH-1:0];
    wire signed [20:0] psum_out2 [HEIGHT-1:0][WIDTH-1:0];
    wire signed [20:0] psum_in1 [HEIGHT-1:0][WIDTH-1:0];
    wire signed [20:0] psum_in2 [HEIGHT-1:0][WIDTH-1:0];

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

    // filter BRAM
    reg filter_data_we;
    reg [3071:0] filter_data_din;
    wire [9:0] filter_data_addr;
    wire [3071:0] filter_data_dout;

    // indicate whether the pe array can start computing
    reg filter_first_load_done;

    reg [9:0] filter_addr;
    reg [15:0] filter_cycle_count;

    localparam CONV1_FILTER_BASE_ADDR = 0;
    assign filter_data_addr = CONV1_FILTER_BASE_ADDR + filter_addr;

    blk_mem_filter filter_data (
        .clka(filter_clk),
        .wea(filter_data_we),
        .addra(filter_data_addr),
        .dina(filter_data_din),
        .douta(filter_data_dout)
    );

    // load filter data from BRAM
    always @(posedge filter_clk) begin
        if (reset) begin
            filter_first_load_done <= 0;
            filter_data_we <= 0;
            filter_data_din <= 0;
            filter_addr <= 0;
            filter_cycle_count <= 0;
        end else begin
            filter_cycle_count <= filter_cycle_count + 1;

            if (filter_addr < (KERNEL_TYPE ? 5 : 3) - 1) begin
                filter_addr <= filter_addr + 1;
            end

            if (filter_cycle_count == 2) begin
                filter_first_load_done <= 1;
            end

            if (filter_cycle_count >= 2 && filter_addr < 2 + (KERNEL_TYPE ? 5 : 3)) begin
                for (integer i = 0; i < HEIGHT; i = i + 1) begin
                    if (i % (KERNEL_TYPE ? 5 : 3) == filter_cycle_count - 2) begin
                        for (integer j = 0; j < WIDTH; j = j + 2) begin
                            automatic integer index = i / (KERNEL_TYPE ? 5 : 3) * (WIDTH / PE_TILE_WIDTH)
                                                    + j / PE_TILE_WIDTH;
                            for (integer k = 0; k < 5; k = k + 1) begin
                                filter_buffer[i][j/2][k] <= filter_data_dout[(index * (KERNEL_TYPE ? 5 : 3) + k) * 8 +: 8];
                            end
                        end
                    end
                end
            end
        end
    end

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

    function [7:0] quantize_relu;
        input wire signed [20:0] psum;

        begin
            automatic integer shifted = psum >>> Q;
            if (shifted < 0) begin
                quantize_relu = 0;
            end else if (shifted > 127) begin
                quantize_relu = 8'd127;
            end else begin
                quantize_relu = shifted[7:0];
            end
        end
    endfunction

    reg [15:0] cycle_count;

    always @(posedge clk) begin
        if (reset || !filter_first_load_done) begin
            cycle_count <= 0;
            for (integer i = 0; i < MAX_PE_TILE_HEIGHT; i = i + 1) begin
                start[i] <= 0;
            end
        end else begin
            // 1: start signal at cycle 0
            // 4: DSP latency
            // kernel_size * kernel_size: MAC pipeline latency
            automatic integer time_start_read = 1 + 4 + (KERNEL_TYPE ? 25 : 9);

            cycle_count <= cycle_count + 1;

            // load ifm data to PEs at the right time
            if (cycle_count % (KERNEL_TYPE ? 5 : 3) == 0) begin
                automatic integer load_count = (cycle_count / (KERNEL_TYPE ? 5 : 3)) % OFM_SIZE;

                // set pe ifm data according to original image
                for (integer i = 0; i < MAX_PE_TILE_HEIGHT; i = i + 1) begin
                    for (integer j = 0; j < MAX_PE_TILE_WIDTH; j = j + 1) begin
                        if (i == 0 || j == PE_TILE_WIDTH-1) begin
                            automatic integer r1 = i + j;
                            automatic integer r2 = r1 + PE_TILE_WIDTH;
                            automatic integer c = load_count < i ? OFM_SIZE + load_count - i : load_count - i;
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
                        if (i % (KERNEL_TYPE ? 5 : 3) == load_count % (KERNEL_TYPE ? 5 : 3)) begin
                            pe_filter_data[i] <= filter_buffer[i];
                        end
                    end
                end
            end

            // store output psum to output buffer at the right time
            if (cycle_count >= time_start_read
                    && cycle_count < (time_start_read + (KERNEL_TYPE ? 5 : 3) * OFM_SIZE)
                    && (cycle_count - time_start_read) % (KERNEL_TYPE ? 5 : 3) == 0) begin
                automatic integer store_count = ((cycle_count - time_start_read) / (KERNEL_TYPE ? 5 : 3)) % OFM_SIZE;

                for (integer i = 0; i < HEIGHT; i = i + 1) begin
                    if ((i + 1) % (KERNEL_TYPE ? 5 : 3) == 0) begin
                        for (integer j = 0; j < WIDTH; j = j + 1) begin
                            automatic integer img_r = i / (KERNEL_TYPE ? 5 : 3);
                            automatic integer img_c = j / PE_TILE_WIDTH;
                            automatic integer img_index = img_r * (WIDTH / PE_TILE_WIDTH) + img_c;
                            automatic integer r = j % PE_TILE_WIDTH;

                            automatic integer index1 = img_index * OFM_SIZE * OFM_SIZE + r * OFM_SIZE + store_count;
                            automatic integer index2 = img_index * OFM_SIZE * OFM_SIZE + (r + PE_TILE_WIDTH) * OFM_SIZE + store_count;

                            pe_output_data[index1] <= quantize_relu(psum_out1[i][j]);
                            pe_output_data[index2] <= quantize_relu(psum_out2[i][j]);
                        end
                    end
                end
            end

            // generate start signals
            for (integer i = 0; i < MAX_PE_TILE_HEIGHT; i = i + 1) begin
                if (cycle_count == i * (KERNEL_TYPE ? 5 : 3)) begin
                    start[i] <= 1;
                end else begin
                    start[i] <= 0;
                end
            end
        end
    end

endmodule
