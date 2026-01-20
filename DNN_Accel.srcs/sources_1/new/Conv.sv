`timescale 1ns / 1ps

module Conv #(
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
    input logic [7:0] out_size,

    input logic [3:0] ifm_channel_tiles,
    input logic [3:0] ofm_channel_tiles,

    input  logic [DATA_WIDTH*16-1:0] ifm_data,
    output logic [15:0]              ifm_addr,

    input  logic [DATA_WIDTH*16-1:0] filter_data,
    output logic [15:0]              filter_addr,

    input  logic [ACC_WIDTH *16-1:0] ofm_rd_data,
    output logic [15:0]              ofm_rd_addr,
    output logic [ACC_WIDTH *16-1:0] ofm_wr_data,
    output logic [15:0]              ofm_wr_addr,
    output logic                     ofm_wr_en,

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

    logic input_fifo_wr_en [0:15];
    logic input_fifo_rd_en [0:15];
    logic input_fifo_full  [0:15];
    logic signed [DATA_WIDTH-1:0] input_fifo_din  [0:15];
    logic signed [DATA_WIDTH-1:0] input_fifo_dout [0:15];

    logic input_fifo_can_write;

    always_comb begin
        input_fifo_can_write = 1;
        for (integer i = 0; i < 16; i++) begin
            if (input_fifo_full[i]) begin
                input_fifo_can_write = 0;
            end
        end
    end

    generate
        for (genvar i = 0; i < 16; i++) begin : INPUT_FIFO_GEN
            xpm_fifo_sync # (

                .FIFO_MEMORY_TYPE          ("auto"),           //string; "auto", "block", "distributed", or "ultra";
                .ECC_MODE                  ("no_ecc"),         //string; "no_ecc" or "en_ecc";
                .FIFO_WRITE_DEPTH          (64),             //positive integer
                .WRITE_DATA_WIDTH          (DATA_WIDTH),               //positive integer
                .WR_DATA_COUNT_WIDTH       (6),               //positive integer
                .PROG_FULL_THRESH          (59),               //positive integer
                .FULL_RESET_VALUE          (0),                //positive integer; 0 or 1
                .USE_ADV_FEATURES          ("0707"),           //string; "0000" to "1F1F"; 
                .READ_MODE                 ("fwft"),            //string; "std" or "fwft";
                .FIFO_READ_LATENCY         (1),                //positive integer;
                .READ_DATA_WIDTH           (DATA_WIDTH),               //positive integer
                .RD_DATA_COUNT_WIDTH       (6),               //positive integer
                .PROG_EMPTY_THRESH         (10),               //positive integer
                .DOUT_RESET_VALUE          ("0"),              //string
                .WAKEUP_TIME               (0)                 //positive integer; 0 or 2;

            ) xpm_fifo_sync_inst (

                .sleep            (1'b0),
                .rst              (~rst_n),
                .wr_clk           (clk),
                .wr_en            (input_fifo_wr_en[i]),
                .din              (input_fifo_din[i]),
                .full             (),
                .overflow         (),
                .prog_full        (input_fifo_full[i]),
                .wr_data_count    (),
                .almost_full      (),
                .wr_ack           (),
                .wr_rst_busy      (),
                .rd_en            (input_fifo_rd_en[i]),
                .dout             (input_fifo_dout[i]),
                .empty            (),
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

    logic filter_fifo_wr_en [0:15];
    logic filter_fifo_rd_en [0:15];
    logic filter_fifo_full  [0:15];
    logic signed [DATA_WIDTH-1:0] filter_fifo_din  [0:15];
    logic signed [DATA_WIDTH-1:0] filter_fifo_dout [0:15];

    logic filter_fifo_can_write;

    always_comb begin
        filter_fifo_can_write = 1;
        for (integer i = 0; i < 16; i++) begin
            if (filter_fifo_full[i]) begin
                filter_fifo_can_write = 0;
            end
        end
    end

    generate
        for (genvar i = 0; i < 16; i++) begin : FILTER_FIFO_GEN
            xpm_fifo_sync # (

                .FIFO_MEMORY_TYPE          ("auto"),           //string; "auto", "block", "distributed", or "ultra";
                .ECC_MODE                  ("no_ecc"),         //string; "no_ecc" or "en_ecc";
                .FIFO_WRITE_DEPTH          (64),             //positive integer
                .WRITE_DATA_WIDTH          (DATA_WIDTH),               //positive integer
                .WR_DATA_COUNT_WIDTH       (6),               //positive integer
                .PROG_FULL_THRESH          (59),               //positive integer
                .FULL_RESET_VALUE          (0),                //positive integer; 0 or 1
                .USE_ADV_FEATURES          ("0707"),           //string; "0000" to "1F1F"; 
                .READ_MODE                 ("fwft"),            //string; "std" or "fwft";
                .FIFO_READ_LATENCY         (1),                //positive integer;
                .READ_DATA_WIDTH           (DATA_WIDTH),               //positive integer
                .RD_DATA_COUNT_WIDTH       (6),               //positive integer
                .PROG_EMPTY_THRESH         (10),               //positive integer
                .DOUT_RESET_VALUE          ("0"),              //string
                .WAKEUP_TIME               (0)                 //positive integer; 0 or 2;

            ) xpm_fifo_sync_inst (

                .sleep            (1'b0),
                .rst              (~rst_n),
                .wr_clk           (clk),
                .wr_en            (filter_fifo_wr_en[i]),
                .din              (filter_fifo_din[i]),
                .full             (),
                .overflow         (),
                .prog_full        (filter_fifo_full[i]),
                .wr_data_count    (),
                .almost_full      (),
                .wr_ack           (),
                .wr_rst_busy      (),
                .rd_en            (filter_fifo_rd_en[i]),
                .dout             (filter_fifo_dout[i]),
                .empty            (),
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

    logic output_fifo_wr_en [0:15];
    logic output_fifo_rd_en [0:15];
    logic output_fifo_empty [0:15];
    logic signed [PE_ACC_WIDTH-1:0] output_fifo_din  [0:15];
    logic signed [PE_ACC_WIDTH-1:0] output_fifo_dout [0:15];

    logic output_fifo_can_read;

    always_comb begin
        output_fifo_can_read = 1;
        for (integer i = 0; i < 16; i++) begin
            if (output_fifo_empty[i]) begin
                output_fifo_can_read = 0;
            end
        end
        for (integer i = 0; i < 16; i++) begin
            output_fifo_rd_en[i] = output_fifo_can_read;
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


    logic       input_is_pad;
    logic       input_done;
    logic [7:0] input_ix;
    logic [7:0] input_iy;
    logic [3:0] input_ifm_tile;

    AGU input_agu (
        .clk(clk),
        .rst_n(rst_n),
        .next(input_fifo_can_write),
        .img_size(img_size),
        .k_size(k_size),
        .stride(stride),
        .padding(padding),
        .out_size(out_size),
        .ifm_channel_tiles(ifm_channel_tiles),
        .ofm_channel_tiles(ofm_channel_tiles),
        .ix(input_ix),
        .iy(input_iy),
        .ox(),
        .oy(),
        .kx(),
        .ky(),
        .ifm_tile(input_ifm_tile),
        .ofm_tile(),
        .is_pad(input_is_pad),
        .done(input_done)
    );

    logic write_input_fifo;
    logic prev_input_is_pad;

    always_comb begin
        ifm_addr = (input_ifm_tile * img_size + input_iy) * img_size + input_ix;
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (integer i = 0; i < 16; i++) begin
                input_fifo_wr_en[i] <= 0;
            end
            write_input_fifo <= 0;
        end else begin
            write_input_fifo <= input_fifo_can_write && !input_done;
            prev_input_is_pad <= input_is_pad;
            for (integer i = 0; i < 16; i++) begin
                input_fifo_wr_en[i] <= write_input_fifo;
            end
            if (write_input_fifo) begin
                for (integer i = 0; i < 16; i++) begin
                    if (prev_input_is_pad) begin
                        input_fifo_din[i] <= '0;
                    end else begin
                        input_fifo_din[i] <= ifm_data[DATA_WIDTH*i +: DATA_WIDTH];
                    end
                end
            end
        end
    end


    logic filter_done;
    logic write_filter_fifo;

    always_comb begin
        filter_done = (filter_addr >= (k_size * k_size * ifm_channel_tiles * ofm_channel_tiles * 16));
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (integer i = 0; i < 16; i++) begin
                filter_fifo_wr_en[i] <= 0;
            end
            write_filter_fifo <= 0;
            filter_addr <= 0;
        end else begin
            if (filter_fifo_can_write && !filter_done) begin
                write_filter_fifo <= 1;
                filter_addr <= filter_addr + 1;
            end else begin
                write_filter_fifo <= 0;
            end
            for (integer i = 0; i < 16; i++) begin
                filter_fifo_wr_en[i] <= write_filter_fifo;
            end
            if (write_filter_fifo) begin
                for (integer i = 0; i < 16; i++) begin
                    filter_fifo_din[i] <= filter_data[DATA_WIDTH*i +: DATA_WIDTH];
                end
            end
        end
    end


    logic [7:0] wait_count;
    logic [31:0] pe_cycle_count;

    localparam PE_WAIT_BEFORE_START = 6;
    localparam PE_WAIT_BEFORE_SWITCH_KERNEL = 3;

    always_comb begin
        for (integer i = 0; i < 16; i++) begin
            if (wait_count == PE_WAIT_BEFORE_START && pe_cycle_count >= i && pe_cycle_count < out_size * out_size + i) begin
                input_fifo_rd_en[i] = 1;
            end else begin
                input_fifo_rd_en[i] = 0;
            end
        end
    end

    always_comb begin
        for (integer i = 0; i < 16; i++) begin
            if (wait_count == PE_WAIT_BEFORE_START && pe_cycle_count < 16) begin
                filter_fifo_rd_en[i] = 1;
            end else begin
                filter_fifo_rd_en[i] = 0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            pe_cycle_count <= 0;
            wait_count <= 0;
        end else begin
            if (wait_count < PE_WAIT_BEFORE_START) begin
                wait_count <= wait_count + 1;
            end else begin
                pe_cycle_count <= pe_cycle_count + 1;

                if (pe_cycle_count == out_size * out_size + 16 + 16 + PE_WAIT_BEFORE_SWITCH_KERNEL) begin
                    pe_cycle_count <= 0;
                end

                // load weights
                weight_in[pe_cycle_count] <= filter_fifo_dout;

                // load ifm
                ifm_in <= input_fifo_dout;

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
    end


    logic [7:0] output_ox;
    logic [7:0] output_oy;
    logic [3:0] output_ofm_tile;

    AGU output_agu (
        .clk(clk),
        .rst_n(rst_n),
        .next(output_fifo_can_read),
        .img_size(img_size),
        .k_size(k_size),
        .stride(stride),
        .padding(padding),
        .out_size(out_size),
        .ifm_channel_tiles(ifm_channel_tiles),
        .ofm_channel_tiles(ofm_channel_tiles),
        .ix(),
        .iy(),
        .ox(output_ox),
        .oy(output_oy),
        .kx(),
        .ky(),
        .ifm_tile(),
        .ofm_tile(output_ofm_tile),
        .is_pad(),
        .done(done)
    );

    logic write_back_1;
    logic write_back_2;
    logic [15:0] prev_output_addr_1;
    logic [15:0] prev_output_addr_2;
    logic signed [ACC_WIDTH-1:0]    prev_ofm_data [0:15];
    logic signed [PE_ACC_WIDTH-1:0] prev_output   [0:15];

    always_comb begin
        ofm_rd_addr = (output_ofm_tile * out_size + output_oy) * out_size + output_ox;
        ofm_wr_addr = prev_output_addr_2;
        ofm_wr_en   = write_back_2;
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            write_back_1 <= 0;
            write_back_2 <= 0;
        end else begin
            write_back_1 <= output_fifo_can_read;
            write_back_2 <= write_back_1;
            prev_output_addr_1 <= (output_ofm_tile * out_size + output_oy) * out_size + output_ox;
            prev_output_addr_2 <= prev_output_addr_1;

            for (integer i = 0; i < 16; i++) begin
                prev_output[i] <= output_fifo_dout[i];
                ofm_wr_data[ACC_WIDTH*i +: ACC_WIDTH] <= $signed(ofm_rd_data[ACC_WIDTH*i +: ACC_WIDTH]) + $signed(prev_output[i]);
            end
        end
    end

endmodule
