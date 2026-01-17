`timescale 1ns / 1ps

module Executor #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH = 26,
    parameter PE_ACC_WIDTH = 21
)(
    input logic clk,
    input logic rst_n,

    input logic [63:0] instruction,

    input  logic [DATA_WIDTH*16-1:0] ifm_rd_data,
    output logic [DATA_WIDTH*16-1:0] ifm_wr_data,
    output logic [15:0]              ifm_addr,
    output logic                     ifm_wr_en,

    input  logic [DATA_WIDTH*16-1:0] filter_data,
    output logic [15:0]              filter_addr,

    input  logic [ACC_WIDTH *16-1:0] ofm_rd_data,
    output logic [ACC_WIDTH *16-1:0] ofm_wr_data,
    output logic [15:0]              ofm_rd_addr,
    output logic [15:0]              ofm_wr_addr,
    output logic                     ofm_wr_en,

    output logic done
);

    logic [3:0]    opcode;
    logic [3:0]    ReLU;
    logic [7:0]    Q;
    logic [15:0]   weight_base_addr;
    logic [7:0]    img_size;
    logic [3:0]    k_size;
    logic [1:0]    stride;
    logic [1:0]    padding;
    logic [7:0]    out_size;
    logic [3:0]    ifm_channel_tiles;
    logic [3:0]    ofm_channel_tiles;

    always_comb begin
        opcode            = instruction[63:60];
        ReLU              = instruction[59:56];
        Q                 = instruction[55:48];
        weight_base_addr  = instruction[47:32];
        img_size          = instruction[31:24];
        k_size            = instruction[23:20];
        stride            = instruction[19:18];
        padding           = instruction[17:16];
        out_size          = instruction[15:8];
        ifm_channel_tiles = instruction[7:4];
        ofm_channel_tiles = instruction[3:0];
    end


    logic conv_enable;
    logic pooling_enable;
    logic postprocess_enable;

    logic conv_done;
    logic pooling_done;
    logic postprocess_done;


    logic [15:0]             conv_ifm_addr;
    logic [15:0]             conv_filter_addr;
    logic [15:0]             conv_ofm_rd_addr;
    logic [ACC_WIDTH*16-1:0] conv_ofm_wr_data;
    logic [15:0]             conv_ofm_wr_addr;
    logic                    conv_ofm_wr_en;

    always_comb begin
        filter_addr = conv_filter_addr + weight_base_addr;
    end

    Conv #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .PE_ACC_WIDTH(PE_ACC_WIDTH)
    ) conv_inst (
        .clk(clk),
        .rst_n(conv_enable),
        .img_size(img_size),
        .k_size(k_size),
        .stride(stride),
        .padding(padding),
        .out_size(out_size),
        .ifm_channel_tiles(ifm_channel_tiles),
        .ofm_channel_tiles(ofm_channel_tiles),
        .ifm_data(ifm_rd_data),
        .ifm_addr(conv_ifm_addr),
        .filter_data(filter_data),
        .filter_addr(conv_filter_addr),
        .ofm_rd_data(ofm_rd_data),
        .ofm_rd_addr(conv_ofm_rd_addr),
        .ofm_wr_data(conv_ofm_wr_data),
        .ofm_wr_addr(conv_ofm_wr_addr),
        .ofm_wr_en(conv_ofm_wr_en),
        .done(conv_done)
    );


    logic [15:0]             pooling_ifm_addr;
    logic [15:0]             pooling_ofm_rd_addr;
    logic [ACC_WIDTH*16-1:0] pooling_ofm_wr_data;
    logic [15:0]             pooling_ofm_wr_addr;
    logic                    pooling_ofm_wr_en;

    Pooling #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) pooling_inst (
        .clk(clk),
        .rst_n(pooling_enable),
        .pooling_type(opcode[1]),
        .img_size(img_size),
        .k_size(k_size),
        .stride(stride),
        .out_size(out_size),
        .ifm_channel_tiles(ifm_channel_tiles),
        .ifm_data(ifm_rd_data),
        .ifm_addr(pooling_ifm_addr),
        .ofm_rd_data(ofm_rd_data),
        .ofm_rd_addr(pooling_ofm_rd_addr),
        .ofm_wr_data(pooling_ofm_wr_data),
        .ofm_wr_addr(pooling_ofm_wr_addr),
        .ofm_wr_en(pooling_ofm_wr_en),
        .done(pooling_done)
    );


    logic [15:0]              post_process_input_rd_addr;
    logic [15:0]              post_process_input_wr_addr;
    logic                     post_process_input_wr_en;
    logic [DATA_WIDTH*16-1:0] post_process_output_data;
    logic [15:0]              post_process_output_addr;
    logic                     post_process_output_en;

    PostProcess #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) post_process_inst (
        .clk(clk),
        .rst_n(postprocess_enable),
        .out_size(out_size),
        .ofm_channel_tiles(ofm_channel_tiles),
        .ReLU(ReLU),
        .Q(Q),
        .input_rd_data(ofm_rd_data),
        .input_rd_addr(post_process_input_rd_addr),
        .input_wr_addr(post_process_input_wr_addr),
        .input_wr_en(post_process_input_wr_en),
        .output_data(post_process_output_data),
        .output_addr(post_process_output_addr),
        .output_en(post_process_output_en),
        .done(postprocess_done)
    );


    always_comb begin
        if (conv_enable) begin
            ifm_addr          = conv_ifm_addr;
            ifm_wr_en         = 1'b0;
            ofm_rd_addr       = conv_ofm_rd_addr;
            ofm_wr_data       = conv_ofm_wr_data;
            ofm_wr_addr       = conv_ofm_wr_addr;
            ofm_wr_en         = conv_ofm_wr_en;
        end else if (pooling_enable) begin
            ifm_addr          = pooling_ifm_addr;
            ifm_wr_en         = 1'b0;
            ofm_rd_addr       = pooling_ofm_rd_addr;
            ofm_wr_data       = pooling_ofm_wr_data;
            ofm_wr_addr       = pooling_ofm_wr_addr;
            ofm_wr_en         = pooling_ofm_wr_en;
        end else if (postprocess_enable) begin
            ifm_addr          = post_process_output_addr;
            ifm_wr_data       = post_process_output_data;
            ifm_wr_en         = post_process_output_en;
            ofm_rd_addr       = post_process_input_rd_addr;
            ofm_wr_data       = {ACC_WIDTH*16{1'b0}};
            ofm_wr_addr       = post_process_input_wr_addr;
            ofm_wr_en         = post_process_input_wr_en;
        end else begin
            ifm_addr          = 16'd0;
            ifm_wr_en         = 1'b0;
            ofm_rd_addr       = 16'd0;
            ofm_wr_data       = {ACC_WIDTH*16{1'b0}};
            ofm_wr_addr       = 16'd0;
            ofm_wr_en         = 1'b0;
        end
    end


    localparam IDLE         = 5'b00001;
    localparam LAYER        = 5'b00010;
    localparam LAYER_WAIT   = 5'b00100;
    localparam POST_PROCESS = 5'b01000;
    localparam DONE         = 5'b10000;

    localparam WAIT_CYCLES = 10;

    logic [4:0] state;
    logic [7:0] wait_counter;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            conv_enable <= 0;
            pooling_enable <= 0;
            postprocess_enable <= 0;
            done <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    conv_enable <= ~opcode[0];
                    pooling_enable <= opcode[0];
                    postprocess_enable <= 0;
                    done <= 0;
                    state <= LAYER;
                end
                LAYER: begin
                    if ((conv_enable && conv_done) ||
                        (pooling_enable && pooling_done)) begin
                        wait_counter <= 0;
                        state <= LAYER_WAIT;
                    end
                end
                LAYER_WAIT: begin
                    wait_counter <= wait_counter + 1;
                    if (wait_counter == WAIT_CYCLES) begin
                        conv_enable <= 0;
                        pooling_enable <= 0;
                        postprocess_enable <= 1;
                        state <= POST_PROCESS;
                    end
                end
                POST_PROCESS: begin
                    if (postprocess_done) begin
                        wait_counter <= 0;
                        state <= DONE;
                    end
                end
                DONE: begin
                    wait_counter <= wait_counter + 1;
                    if (wait_counter == WAIT_CYCLES) begin
                        postprocess_enable <= 0;
                        done <= 1;
                    end
                end
                default: begin
                    conv_enable <= 0;
                    pooling_enable <= 0;
                    postprocess_enable <= 0;
                    done <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
