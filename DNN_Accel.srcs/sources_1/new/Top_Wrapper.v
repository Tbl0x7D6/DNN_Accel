`timescale 1ns / 1ps

module Top_Wrapper (
    input  clk,
    input  rst_n,
    input  start,
    output done,

    // ---- AXI BRAM Controller Interface ----
    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_IFM CLK" *)     input          axi_ifm_clk,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_IFM RST" *)     input          axi_ifm_rst,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_IFM EN" *)      input          axi_ifm_en,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_IFM WE" *)      input  [15:0]  axi_ifm_wr_en,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_IFM ADDR" *)    input  [14:0]  axi_ifm_addr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_IFM DIN" *)     input  [127:0] axi_ifm_wr_data,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_IFM DOUT" *)    output [127:0] axi_ifm_rd_data,

    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_FILTER CLK" *)  input          axi_filter_clk,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_FILTER RST" *)  input          axi_filter_rst,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_FILTER EN" *)   input          axi_filter_en,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_FILTER WE" *)   input  [15:0]  axi_filter_wr_en,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_FILTER ADDR" *) input  [17:0]  axi_filter_addr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_FILTER DIN" *)  input  [127:0] axi_filter_wr_data,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_FILTER DOUT" *) output [127:0] axi_filter_rd_data,

    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_INST CLK" *)    input          axi_inst_clk,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_INST RST" *)    input          axi_inst_rst,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_INST EN" *)     input          axi_inst_en,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_INST WE" *)     input  [7:0]   axi_inst_wr_en,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_INST ADDR" *)   input  [11:0]  axi_inst_addr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_INST DIN" *)    input  [63:0]  axi_inst_wr_data,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_INST DOUT" *)   output [63:0]  axi_inst_rd_data
);

    Top top_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .done(done),

        .axi_ifm_clk(axi_ifm_clk),
        .axi_ifm_rst(axi_ifm_rst),
        .axi_ifm_en(axi_ifm_en),
        .axi_ifm_wr_en(axi_ifm_wr_en),
        .axi_ifm_addr(axi_ifm_addr),
        .axi_ifm_wr_data(axi_ifm_wr_data),
        .axi_ifm_rd_data(axi_ifm_rd_data),

        .axi_filter_clk(axi_filter_clk),
        .axi_filter_rst(axi_filter_rst),
        .axi_filter_en(axi_filter_en),
        .axi_filter_wr_en(axi_filter_wr_en),
        .axi_filter_addr(axi_filter_addr),
        .axi_filter_wr_data(axi_filter_wr_data),
        .axi_filter_rd_data(axi_filter_rd_data),

        .axi_inst_clk(axi_inst_clk),
        .axi_inst_rst(axi_inst_rst),
        .axi_inst_en(axi_inst_en),
        .axi_inst_wr_en(axi_inst_wr_en),
        .axi_inst_addr(axi_inst_addr),
        .axi_inst_wr_data(axi_inst_wr_data),
        .axi_inst_rd_data(axi_inst_rd_data)
    );

endmodule
