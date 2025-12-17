// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.4 (win64) Build 2086221 Fri Dec 15 20:55:39 MST 2017
// Date        : Wed Dec 17 16:50:19 2025
// Host        : DESKTOP-GQ0QCNC running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/Users/be/DNN_Accel/DNN_Accel.srcs/sources_1/ip/blk_mem_fm/blk_mem_fm_stub.v
// Design      : blk_mem_fm
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z035ffg676-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_1,Vivado 2017.4" *)
module blk_mem_fm(clka, wea, addra, dina, douta, clkb, web, addrb, dinb, 
  doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,wea[0:0],addra[7:0],dina[511:0],douta[511:0],clkb,web[0:0],addrb[7:0],dinb[511:0],doutb[511:0]" */;
  input clka;
  input [0:0]wea;
  input [7:0]addra;
  input [511:0]dina;
  output [511:0]douta;
  input clkb;
  input [0:0]web;
  input [7:0]addrb;
  input [511:0]dinb;
  output [511:0]doutb;
endmodule
