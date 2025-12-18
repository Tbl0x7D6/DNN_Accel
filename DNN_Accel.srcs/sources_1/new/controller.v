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
    input wire fm_read_clk,
    input wire fm_write_clk,
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
    localparam OFM_SIZE_POOL = OFM_SIZE / 2;

    // quantization, Q = Q_in + Q_w - Q_out
    // psum_out should be shifted right by Q bits
    localparam Q = 9;

    // start signals for each row of a PE tile
    reg start [MAX_PE_TILE_HEIGHT-1:0];

    // original layout
    reg signed [7:0] input_image [31:0][31:0];

    // data buffer of bram, can update every KERNEL_SIZE cycles
    reg signed [7:0] filter_buffer [HEIGHT-1:0][WIDTH/2-1:0][4:0];

    // same ifm data for all PEs
    reg signed [7:0] pe_ifm_data1 [MAX_PE_TILE_HEIGHT-1:0][MAX_PE_TILE_WIDTH-1:0][4:0];
    reg signed [7:0] pe_ifm_data2 [MAX_PE_TILE_HEIGHT-1:0][MAX_PE_TILE_WIDTH-1:0][4:0];

    // same filter data for each 2 PEs
    reg signed [7:0] pe_filter_data [HEIGHT-1:0][WIDTH/2-1:0][4:0];

    // cache ofm even column for later pooling
    // only used in conv1
    reg signed [7:0] pe_column_cache [7:0][31:0];

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

    // controller state
    reg [15:0] cycle_count;
    // (refer to data delivery pattern) sliding window (from left to right) position
    reg [15:0] load_count;
    // pick which column to store to buffer
    reg [15:0] store_count;

    // filter BRAM
    reg filter_data_we;
    reg [3071:0] filter_data_din;
    wire [9:0] filter_data_addr;
    wire [3071:0] filter_data_dout;

    // indicate whether the pe array can start computing
    reg filter_first_load_done;

    // tracked by bram
    reg [15:0] last_load_round;
    // set by pe array controller main logic
    reg [15:0] current_load_round;

    reg [9:0] filter_addr;
    reg [15:0] filter_cycle_count;

    localparam CONV1_FILTER_BASE_ADDR = 0;
    assign filter_data_addr = CONV1_FILTER_BASE_ADDR + filter_addr;

    xpm_memory_spram # (

        // Common module parameters
        .MEMORY_SIZE             (3072*1024),            //positive integer
        .MEMORY_PRIMITIVE        ("auto"),          //string; "auto", "distributed", "block" or "ultra";
        .MEMORY_INIT_FILE        ("none"),          //string; "none" or "<filename>.mem" 
        .MEMORY_INIT_PARAM       (""    ),          //string;
        .USE_MEM_INIT            (0),               //integer; 0,1
        .WAKEUP_TIME             ("disable_sleep"), //string; "disable_sleep" or "use_sleep_pin" 
        .MESSAGE_CONTROL         (0),               //integer; 0,1
        .MEMORY_OPTIMIZATION     ("true"),          //string; "true", "false" 

        // Port A module parameters
        .WRITE_DATA_WIDTH_A      (3072),              //positive integer
        .READ_DATA_WIDTH_A       (3072),              //positive integer
        .BYTE_WRITE_WIDTH_A      (3072),              //integer; 8, 9, or WRITE_DATA_WIDTH_A value
        .ADDR_WIDTH_A            (10),               //positive integer
        .READ_RESET_VALUE_A      ("0"),             //string
        .ECC_MODE                ("no_ecc"),        //string; "no_ecc", "encode_only", "decode_only" or "both_encode_and_decode" 
        .AUTO_SLEEP_TIME         (0),               //Do not Change
        .READ_LATENCY_A          (2),               //non-negative integer
        .WRITE_MODE_A            ("write_first")     //string; "write_first", "read_first", "no_change" 

    ) filter_data (

        // Common module ports
        .sleep                   (1'b0),

        // Port A module ports
        .clka                    (filter_clk),
        .rsta                    (reset),
        .ena                     (1),
        .regcea                  (1),
        .wea                     (filter_data_we),
        .addra                   (filter_data_addr),
        .dina                    (filter_data_din),
        .injectsbiterra          (1'b0),
        .injectdbiterra          (1'b0),
        .douta                   (filter_data_dout),
        .sbiterra                (),
        .dbiterra                ()

    );

    // load filter data from BRAM
    always @(posedge filter_clk) begin
        if (reset) begin
            filter_first_load_done <= 0;
            filter_data_we <= 0;
            filter_data_din <= 0;
            filter_addr <= 0;
            filter_cycle_count <= 0;
            last_load_round <= -1;
        end else begin
            if (last_load_round != current_load_round) begin
                filter_addr <= current_load_round * (KERNEL_TYPE ? 5 : 3);
                filter_cycle_count <= 0;
                last_load_round <= current_load_round;
            end else begin
                filter_cycle_count <= filter_cycle_count + 1;

                if (filter_addr < (last_load_round + 1) * (KERNEL_TYPE ? 5 : 3)) begin
                    filter_addr <= filter_addr + 1;
                end

                if (filter_cycle_count == 2) begin
                    filter_first_load_done <= 1;
                end
            end

            // bram latency is 2 cycles
            if (filter_cycle_count >= 2 && filter_cycle_count < 2 + (KERNEL_TYPE ? 5 : 3)) begin
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

    // output feature map FIFO
    reg ofm_fifo_wr_en;
    reg [511:0] ofm_fifo_din [7:0];
    wire ofm_fifo_empty [7:0];
    wire [511:0] ofm_fifo_dout [7:0];

    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_ofm_fifo
            xpm_fifo_async # (

                .FIFO_MEMORY_TYPE          ("auto"),           //string; "auto", "block", or "distributed";
                .ECC_MODE                  ("no_ecc"),         //string; "no_ecc" or "en_ecc";
                .RELATED_CLOCKS            (1),                //positive integer; 0 or 1
                .FIFO_WRITE_DEPTH          (16),             //positive integer
                .WRITE_DATA_WIDTH          (512),               //positive integer
                .WR_DATA_COUNT_WIDTH       (4),               //positive integer
                .PROG_FULL_THRESH          (10),               //positive integer
                .FULL_RESET_VALUE          (0),                //positive integer; 0 or 1
                .USE_ADV_FEATURES          ("0707"),           //string; "0000" to "1F1F"; 
                .READ_MODE                 ("fwft"),            //string; "std" or "fwft";
                .FIFO_READ_LATENCY         (1),                //positive integer;
                .READ_DATA_WIDTH           (512),               //positive integer
                .RD_DATA_COUNT_WIDTH       (4),               //positive integer
                .PROG_EMPTY_THRESH         (10),               //positive integer
                .DOUT_RESET_VALUE          ("0"),              //string
                .CDC_SYNC_STAGES           (2),                //positive integer
                .WAKEUP_TIME               (0)                 //positive integer; 0 or 2;

            ) ofm_fifo_inst (

                .rst              (reset),
                .wr_clk           (clk),
                .wr_en            (ofm_fifo_wr_en),
                .din              (ofm_fifo_din[i]),
                .full             (),
                .overflow         (),
                .prog_full        (),
                .wr_data_count    (),
                .almost_full      (),
                .wr_ack           (),
                .wr_rst_busy      (),
                .rd_clk           (fm_write_clk),
                .rd_en            (!ofm_fifo_empty[i]),
                .dout             (ofm_fifo_dout[i]),
                .empty            (ofm_fifo_empty[i]),
                .underflow        (),
                .rd_rst_busy      (),
                .prog_empty       (),
                .rd_data_count    (),
                .almost_empty     (),
                .data_valid       (),
                .sleep            (1'b0),
                .injectsbiterr    (1'b0),
                .injectdbiterr    (1'b0),
                .sbiterr          (),
                .dbiterr          ()

            );
        end
    endgenerate

    // feature map BRAM
    wire [7:0] fm_data_read_addr [7:0];
    wire [7:0] fm_data_write_addr [7:0];
    wire [511:0] fm_data_dout [7:0];

    reg [7:0] fm_write_addr [7:0];

    localparam CONV1_OFM_BASE_ADDR = 0;
    generate
        for (i = 0; i < 8; i = i + 1) begin
            assign fm_data_write_addr[i] = CONV1_OFM_BASE_ADDR + fm_write_addr[i];
        end
    endgenerate

    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_fm_bram
            xpm_memory_tdpram # (

                // Common module parameters
                .MEMORY_SIZE             (512*256),            //positive integer
                .MEMORY_PRIMITIVE        ("auto"),          //string; "auto", "distributed", "block" or "ultra";
                .CLOCKING_MODE           ("independent_clock"),  //string; "common_clock", "independent_clock" 
                .MEMORY_INIT_FILE        ("none"),          //string; "none" or "<filename>.mem" 
                .MEMORY_INIT_PARAM       (""    ),          //string;
                .USE_MEM_INIT            (0),               //integer; 0,1
                .WAKEUP_TIME             ("disable_sleep"), //string; "disable_sleep" or "use_sleep_pin" 
                .MESSAGE_CONTROL         (0),               //integer; 0,1
                .ECC_MODE                ("no_ecc"),        //string; "no_ecc", "encode_only", "decode_only" or "both_encode_and_decode" 
                .AUTO_SLEEP_TIME         (0),               //Do not Change
                .USE_EMBEDDED_CONSTRAINT (0),               //integer: 0,1
                .MEMORY_OPTIMIZATION     ("true"),          //string; "true", "false" 

                // Port A module parameters
                .WRITE_DATA_WIDTH_A      (512),              //positive integer
                .READ_DATA_WIDTH_A       (512),              //positive integer
                .BYTE_WRITE_WIDTH_A      (512),              //integer; 8, 9, or WRITE_DATA_WIDTH_A value
                .ADDR_WIDTH_A            (8),               //positive integer
                .READ_RESET_VALUE_A      ("0"),             //string
                .READ_LATENCY_A          (2),               //non-negative integer
                .WRITE_MODE_A            ("write_first"),     //string; "write_first", "read_first", "no_change" 

                // Port B module parameters
                .WRITE_DATA_WIDTH_B      (512),              //positive integer
                .READ_DATA_WIDTH_B       (512),              //positive integer
                .BYTE_WRITE_WIDTH_B      (512),              //integer; 8, 9, or WRITE_DATA_WIDTH_B value
                .ADDR_WIDTH_B            (8),               //positive integer
                .READ_RESET_VALUE_B      ("0"),             //vector of READ_DATA_WIDTH_B bits
                .READ_LATENCY_B          (2),               //non-negative integer
                .WRITE_MODE_B            ("write_first")      //string; "write_first", "read_first", "no_change" 

            ) fm_bram_inst (

                // Common module ports
                .sleep                   (1'b0),

                // Port A module ports
                .clka                    (fm_read_clk),
                .rsta                    (reset),
                .ena                     (1),
                .regcea                  (),
                .wea                     (0),
                .addra                   (fm_data_read_addr[i]),
                .dina                    (512'b0),
                .injectsbiterra          (1'b0),
                .injectdbiterra          (1'b0),
                .douta                   (fm_data_dout[i]),
                .sbiterra                (),
                .dbiterra                (),

                // Port B module ports
                .clkb                    (fm_write_clk),
                .rstb                    (reset),
                .enb                     (1),
                .regceb                  (),
                .web                     (!ofm_fifo_empty[i]),
                .addrb                   (fm_data_write_addr[i]),
                .dinb                    (ofm_fifo_dout[i]),
                .injectsbiterrb          (1'b0),
                .injectdbiterrb          (1'b0),
                .doutb                   (),
                .sbiterrb                (),
                .dbiterrb                ()

            );
        end
    endgenerate

    always @(posedge fm_write_clk) begin
        for (integer i = 0; i < 8; i = i + 1) begin
            if (reset) begin
                fm_write_addr[i] <= 0;
            end else begin
                fm_write_addr[i] <= fm_write_addr[i] + !ofm_fifo_empty[i];
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

    always @(posedge clk) begin
        if (reset || !filter_first_load_done) begin
            cycle_count <= 0;
            load_count <= 0;
            store_count <= 0;
            current_load_round <= 0;
            for (integer i = 0; i < MAX_PE_TILE_HEIGHT; i = i + 1) begin
                start[i] <= 0;
            end
        end else begin
            // 1: start signal at cycle 0
            // 4: DSP latency
            // kernel_size * kernel_size: MAC pipeline latency
            automatic integer time_start_read = 1 + 4 + (KERNEL_TYPE ? 25 : 9);

            // for conv1, we can start pooling after first 2 columns of ofm are ready
            automatic integer time_start_pooling = time_start_read + (KERNEL_TYPE ? 5 : 3) + 1;

            cycle_count <= cycle_count + 1;

            // load ifm data to PEs at the right time
            if (cycle_count % (KERNEL_TYPE ? 5 : 3) == 0) begin
                if (load_count == OFM_SIZE - 1) begin
                    load_count <= 0;
                end else begin
                    load_count <= load_count + 1;
                end

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
                end else if (load_count == (KERNEL_TYPE ? 5 : 3)) begin
                    // request next filter load
                    current_load_round <= current_load_round + 1;
                end
            end

            // store output psum to output buffer at the right time
            if (cycle_count >= time_start_read && (cycle_count - time_start_read) % (KERNEL_TYPE ? 5 : 3) == 0) begin
                if (store_count == OFM_SIZE - 1) begin
                    store_count <= 0;
                end else begin
                    store_count <= store_count + 1;
                end

                if (store_count % 2 == 0) begin
                    for (integer i = 0; i < HEIGHT; i = i + 1) begin
                        if ((i + 1) % (KERNEL_TYPE ? 5 : 3) == 0) begin
                            for (integer j = 0; j < WIDTH; j = j + 1) begin
                                automatic integer img_r = i / (KERNEL_TYPE ? 5 : 3);
                                automatic integer img_c = j / PE_TILE_WIDTH;
                                automatic integer img_index = img_r * (WIDTH / PE_TILE_WIDTH) + img_c;
                                automatic integer r = j % PE_TILE_WIDTH;

                                pe_column_cache[img_index][r] <= quantize_relu(psum_out1[i][j]);
                                pe_column_cache[img_index][r + PE_TILE_WIDTH] <= quantize_relu(psum_out2[i][j]);
                            end
                        end
                    end
                end else begin
                    // perform 2x2 max pooling
                    for (integer img_index = 0; img_index < (HEIGHT / (KERNEL_TYPE ? 5 : 3)) * (WIDTH / PE_TILE_WIDTH); img_index = img_index + 1) begin
                        for (integer r = 0; r < OFM_SIZE_POOL; r = r + 1) begin
                            automatic integer pe_r = r * 2;
                            automatic integer i = (img_index / (WIDTH / PE_TILE_WIDTH) + 1) * (KERNEL_TYPE ? 5 : 3) - 1;
                            automatic integer j = (img_index % (WIDTH / PE_TILE_WIDTH)) * PE_TILE_WIDTH;

                            automatic integer block = img_index / (WIDTH / PE_TILE_WIDTH);
                            automatic integer byte_position = (img_index % (WIDTH / PE_TILE_WIDTH)) * OFM_SIZE_POOL + r;

                            automatic reg [7:0] val1 = pe_column_cache[img_index][pe_r];
                            automatic reg [7:0] val2 = pe_column_cache[img_index][pe_r + 1];
                            automatic reg [7:0] val3 = quantize_relu(pe_r < PE_TILE_WIDTH
                                ? psum_out1[i][j + pe_r]
                                : psum_out2[i][j + pe_r - PE_TILE_WIDTH]
                            );
                            automatic reg [7:0] val4 = quantize_relu(pe_r + 1 < PE_TILE_WIDTH
                                ? psum_out1[i][j + pe_r + 1]
                                : psum_out2[i][j + pe_r + 1 - PE_TILE_WIDTH]
                            );

                            automatic reg [7:0] max1 = (val1 > val2) ? val1 : val2;
                            automatic reg [7:0] max2 = (val3 > val4) ? val3 : val4;
                            ofm_fifo_din[block][byte_position * 8 +: 8] <= (max1 > max2) ? max1 : max2;
                        end
                    end
                end
            end

            // generate ofm fifo write enable signal
            if (cycle_count >= time_start_read
                    && cycle_count < time_start_read + 640
                    && (cycle_count - time_start_read) % (KERNEL_TYPE ? 5 : 3) == 0
                    && (store_count % 2 == 1)) begin
                ofm_fifo_wr_en <= 1;
            end else begin
                ofm_fifo_wr_en <= 0;
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
