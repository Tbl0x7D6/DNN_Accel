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

    (* ram_style = "block" *) logic signed [DATA_WIDTH*16-1:0] ifm_data    [0:2048-1];
    (* ram_style = "block" *) logic signed [DATA_WIDTH*16-1:0] filter_data [0:4608-1];
    (* ram_style = "block" *) logic signed [ACC_WIDTH *16-1:0] ofm_data    [0:2048-1];

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

    logic [7:0] out_size;
    always_comb begin
        out_size = ((img_size + 2 * padding - k_size) / stride) + 1;
    end


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
        .ifm_channels(ifm_channels),
        .ofm_channels(ofm_channels),
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

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (integer i = 0; i < 16; i++) begin
                input_fifo_wr_en[i] <= 0;
            end
        end else begin
            for (integer i = 0; i < 16; i++) begin
                input_fifo_wr_en[i] <= input_fifo_can_write && !input_done;
            end
            if (input_fifo_can_write && !input_done) begin
                automatic logic [15:0] addr = (input_iy * img_size + input_ix) * (ifm_channels / 16) + input_ifm_tile;
                for (integer i = 0; i < 16; i++) begin
                    if (input_is_pad) begin
                        input_fifo_din[i] <= '0;
                    end else begin
                        input_fifo_din[i] <= ifm_data[addr][DATA_WIDTH*i +: DATA_WIDTH];
                    end
                end
            end
        end
    end


    logic [7:0] wait_count;
    logic [31:0] pe_cycle_count;

    logic [3:0] pe_kx;
    logic [3:0] pe_ky;
    logic [3:0] pe_ifm_tile;
    logic [3:0] pe_ofm_tile;

    AGU pe_agu (
        .clk(clk),
        .rst_n(rst_n),
        .next(wait_count >= 5 && pe_cycle_count < out_size * out_size),
        .img_size(img_size),
        .k_size(k_size),
        .stride(stride),
        .padding(padding),
        .ifm_channels(ifm_channels),
        .ofm_channels(ofm_channels),
        .ix(),
        .iy(),
        .ox(),
        .oy(),
        .kx(pe_kx),
        .ky(pe_ky),
        .ifm_tile(pe_ifm_tile),
        .ofm_tile(pe_ofm_tile),
        .is_pad(),
        .done()
    );

    always_comb begin
        for (integer i = 0; i < 16; i++) begin
            if (wait_count == 5 && pe_cycle_count >= i && pe_cycle_count < out_size * out_size + i) begin
                input_fifo_rd_en[i] = 1;
            end else begin
                input_fifo_rd_en[i] = 0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            pe_cycle_count <= 0;
            wait_count <= 0;

            // reset ofm_data, only for test
            // for (integer i = 0; i < 2048; i++) begin
            //     ofm_data[i] <= 0;
            // end
        end else begin
            if (wait_count < 5) begin
                wait_count <= wait_count + 1;
            end else begin
                pe_cycle_count <= pe_cycle_count + 1;

                // switch to next kernel position
                if (pe_cycle_count >= out_size * out_size + 16 + 16 + 5) begin
                    pe_cycle_count <= 0;
                end

                // load weights
                if (pe_cycle_count < 16) begin
                    automatic logic [15:0] addr = (pe_ky * k_size + pe_kx) * ifm_channels * (ofm_channels / 16)
                                                        + (pe_ifm_tile * 16 + pe_cycle_count) * (ofm_channels / 16)
                                                        + pe_ofm_tile;
                    for (integer oc = 0; oc < 16; oc++) begin
                        weight_in[pe_cycle_count][oc] <= filter_data[addr][DATA_WIDTH*oc +: DATA_WIDTH];
                    end
                end

                // load ifm
                for (integer i = 0; i < 16; i++) begin
                    ifm_in[i] <= input_fifo_dout[i];
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
        .ifm_channels(ifm_channels),
        .ofm_channels(ofm_channels),
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

    logic write_back;
    logic [15:0] prev_addr;
    logic signed [ACC_WIDTH-1:0]    prev_ofm_data [0:15];
    logic signed [PE_ACC_WIDTH-1:0] prev_output   [0:15];

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            write_back <= 0;
        end else begin
            if (output_fifo_can_read) begin
                automatic logic [15:0] addr = (output_oy * out_size + output_ox) * (ofm_channels / 16) + output_ofm_tile;
                for (integer i = 0; i < 16; i++) begin
                    prev_ofm_data[i] <= ofm_data[addr][ACC_WIDTH*i +: ACC_WIDTH];
                    prev_output[i]   <= output_fifo_dout[i];
                end
                prev_addr <= addr;
                write_back <= 1;
            end else begin
                write_back <= 0;
            end

            if (write_back) begin
                for (integer i = 0; i < 16; i++) begin
                    ofm_data[prev_addr][ACC_WIDTH*i +: ACC_WIDTH] <= prev_ofm_data[i] + prev_output[i];
                end
            end
        end
    end

endmodule
