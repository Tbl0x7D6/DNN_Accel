// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.4 (win64) Build 2086221 Fri Dec 15 20:55:39 MST 2017
// Date        : Mon Dec  8 20:22:43 2025
// Host        : DESKTOP-GQ0QCNC running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               c:/Users/be/DNN_Accel/DNN_Accel.srcs/sources_1/ip/xbip_dsp48_macro_0/xbip_dsp48_macro_0_sim_netlist.v
// Design      : xbip_dsp48_macro_0
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7z035ffg676-2
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "xbip_dsp48_macro_0,xbip_dsp48_macro_v3_0_15,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "xbip_dsp48_macro_v3_0_15,Vivado 2017.4" *) 
(* NotValidForBitStream *)
module xbip_dsp48_macro_0
   (CLK,
    A,
    B,
    P);
  (* x_interface_info = "xilinx.com:signal:clock:1.0 clk_intf CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME clk_intf, ASSOCIATED_BUSIF p_intf:pcout_intf:carrycascout_intf:carryout_intf:bcout_intf:acout_intf:concat_intf:d_intf:c_intf:b_intf:a_intf:bcin_intf:acin_intf:pcin_intf:carryin_intf:carrycascin_intf:sel_intf, ASSOCIATED_RESET SCLR:SCLRD:SCLRA:SCLRB:SCLRCONCAT:SCLRC:SCLRM:SCLRP:SCLRSEL, ASSOCIATED_CLKEN CE:CED:CED1:CED2:CED3:CEA:CEA1:CEA2:CEA3:CEA4:CEB:CEB1:CEB2:CEB3:CEB4:CECONCAT:CECONCAT3:CECONCAT4:CECONCAT5:CEC:CEC1:CEC2:CEC3:CEC4:CEC5:CEM:CEP:CESEL:CESEL1:CESEL2:CESEL3:CESEL4:CESEL5, FREQ_HZ 100000000, PHASE 0.000" *) input CLK;
  (* x_interface_info = "xilinx.com:signal:data:1.0 a_intf DATA" *) (* x_interface_parameter = "XIL_INTERFACENAME a_intf, LAYERED_METADATA undef" *) input [23:0]A;
  (* x_interface_info = "xilinx.com:signal:data:1.0 b_intf DATA" *) (* x_interface_parameter = "XIL_INTERFACENAME b_intf, LAYERED_METADATA undef" *) input [7:0]B;
  (* x_interface_info = "xilinx.com:signal:data:1.0 p_intf DATA" *) (* x_interface_parameter = "XIL_INTERFACENAME p_intf, LAYERED_METADATA undef" *) output [31:0]P;

  wire [23:0]A;
  wire [7:0]B;
  wire CLK;
  wire [31:0]P;
  wire NLW_U0_CARRYCASCOUT_UNCONNECTED;
  wire NLW_U0_CARRYOUT_UNCONNECTED;
  wire [29:0]NLW_U0_ACOUT_UNCONNECTED;
  wire [17:0]NLW_U0_BCOUT_UNCONNECTED;
  wire [47:0]NLW_U0_PCOUT_UNCONNECTED;

  (* C_A_WIDTH = "24" *) 
  (* C_B_WIDTH = "8" *) 
  (* C_CONCAT_WIDTH = "48" *) 
  (* C_CONSTANT_1 = "1" *) 
  (* C_C_WIDTH = "48" *) 
  (* C_D_WIDTH = "18" *) 
  (* C_HAS_A = "1" *) 
  (* C_HAS_ACIN = "0" *) 
  (* C_HAS_ACOUT = "0" *) 
  (* C_HAS_B = "1" *) 
  (* C_HAS_BCIN = "0" *) 
  (* C_HAS_BCOUT = "0" *) 
  (* C_HAS_C = "0" *) 
  (* C_HAS_CARRYCASCIN = "0" *) 
  (* C_HAS_CARRYCASCOUT = "0" *) 
  (* C_HAS_CARRYIN = "0" *) 
  (* C_HAS_CARRYOUT = "0" *) 
  (* C_HAS_CE = "0" *) 
  (* C_HAS_CEA = "0" *) 
  (* C_HAS_CEB = "0" *) 
  (* C_HAS_CEC = "0" *) 
  (* C_HAS_CECONCAT = "0" *) 
  (* C_HAS_CED = "0" *) 
  (* C_HAS_CEM = "0" *) 
  (* C_HAS_CEP = "0" *) 
  (* C_HAS_CESEL = "0" *) 
  (* C_HAS_CONCAT = "0" *) 
  (* C_HAS_D = "0" *) 
  (* C_HAS_INDEP_CE = "0" *) 
  (* C_HAS_INDEP_SCLR = "0" *) 
  (* C_HAS_PCIN = "0" *) 
  (* C_HAS_PCOUT = "0" *) 
  (* C_HAS_SCLR = "0" *) 
  (* C_HAS_SCLRA = "0" *) 
  (* C_HAS_SCLRB = "0" *) 
  (* C_HAS_SCLRC = "0" *) 
  (* C_HAS_SCLRCONCAT = "0" *) 
  (* C_HAS_SCLRD = "0" *) 
  (* C_HAS_SCLRM = "0" *) 
  (* C_HAS_SCLRP = "0" *) 
  (* C_HAS_SCLRSEL = "0" *) 
  (* C_LATENCY = "-1" *) 
  (* C_MODEL_TYPE = "0" *) 
  (* C_OPMODES = "000100100000010100000000" *) 
  (* C_P_LSB = "0" *) 
  (* C_P_MSB = "31" *) 
  (* C_REG_CONFIG = "00000000000011000011000001000100" *) 
  (* C_SEL_WIDTH = "0" *) 
  (* C_TEST_CORE = "0" *) 
  (* C_VERBOSITY = "0" *) 
  (* C_XDEVICEFAMILY = "zynq" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  xbip_dsp48_macro_0_xbip_dsp48_macro_v3_0_15 U0
       (.A(A),
        .ACIN({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .ACOUT(NLW_U0_ACOUT_UNCONNECTED[29:0]),
        .B(B),
        .BCIN({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .BCOUT(NLW_U0_BCOUT_UNCONNECTED[17:0]),
        .C({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .CARRYCASCIN(1'b0),
        .CARRYCASCOUT(NLW_U0_CARRYCASCOUT_UNCONNECTED),
        .CARRYIN(1'b0),
        .CARRYOUT(NLW_U0_CARRYOUT_UNCONNECTED),
        .CE(1'b1),
        .CEA(1'b1),
        .CEA1(1'b1),
        .CEA2(1'b1),
        .CEA3(1'b1),
        .CEA4(1'b1),
        .CEB(1'b1),
        .CEB1(1'b1),
        .CEB2(1'b1),
        .CEB3(1'b1),
        .CEB4(1'b1),
        .CEC(1'b1),
        .CEC1(1'b1),
        .CEC2(1'b1),
        .CEC3(1'b1),
        .CEC4(1'b1),
        .CEC5(1'b1),
        .CECONCAT(1'b1),
        .CECONCAT3(1'b1),
        .CECONCAT4(1'b1),
        .CECONCAT5(1'b1),
        .CED(1'b1),
        .CED1(1'b1),
        .CED2(1'b1),
        .CED3(1'b1),
        .CEM(1'b1),
        .CEP(1'b1),
        .CESEL(1'b1),
        .CESEL1(1'b1),
        .CESEL2(1'b1),
        .CESEL3(1'b1),
        .CESEL4(1'b1),
        .CESEL5(1'b1),
        .CLK(CLK),
        .CONCAT({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .D({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .P(P),
        .PCIN({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .PCOUT(NLW_U0_PCOUT_UNCONNECTED[47:0]),
        .SCLR(1'b0),
        .SCLRA(1'b0),
        .SCLRB(1'b0),
        .SCLRC(1'b0),
        .SCLRCONCAT(1'b0),
        .SCLRD(1'b0),
        .SCLRM(1'b0),
        .SCLRP(1'b0),
        .SCLRSEL(1'b0),
        .SEL(1'b0));
endmodule

(* C_A_WIDTH = "24" *) (* C_B_WIDTH = "8" *) (* C_CONCAT_WIDTH = "48" *) 
(* C_CONSTANT_1 = "1" *) (* C_C_WIDTH = "48" *) (* C_D_WIDTH = "18" *) 
(* C_HAS_A = "1" *) (* C_HAS_ACIN = "0" *) (* C_HAS_ACOUT = "0" *) 
(* C_HAS_B = "1" *) (* C_HAS_BCIN = "0" *) (* C_HAS_BCOUT = "0" *) 
(* C_HAS_C = "0" *) (* C_HAS_CARRYCASCIN = "0" *) (* C_HAS_CARRYCASCOUT = "0" *) 
(* C_HAS_CARRYIN = "0" *) (* C_HAS_CARRYOUT = "0" *) (* C_HAS_CE = "0" *) 
(* C_HAS_CEA = "0" *) (* C_HAS_CEB = "0" *) (* C_HAS_CEC = "0" *) 
(* C_HAS_CECONCAT = "0" *) (* C_HAS_CED = "0" *) (* C_HAS_CEM = "0" *) 
(* C_HAS_CEP = "0" *) (* C_HAS_CESEL = "0" *) (* C_HAS_CONCAT = "0" *) 
(* C_HAS_D = "0" *) (* C_HAS_INDEP_CE = "0" *) (* C_HAS_INDEP_SCLR = "0" *) 
(* C_HAS_PCIN = "0" *) (* C_HAS_PCOUT = "0" *) (* C_HAS_SCLR = "0" *) 
(* C_HAS_SCLRA = "0" *) (* C_HAS_SCLRB = "0" *) (* C_HAS_SCLRC = "0" *) 
(* C_HAS_SCLRCONCAT = "0" *) (* C_HAS_SCLRD = "0" *) (* C_HAS_SCLRM = "0" *) 
(* C_HAS_SCLRP = "0" *) (* C_HAS_SCLRSEL = "0" *) (* C_LATENCY = "-1" *) 
(* C_MODEL_TYPE = "0" *) (* C_OPMODES = "000100100000010100000000" *) (* C_P_LSB = "0" *) 
(* C_P_MSB = "31" *) (* C_REG_CONFIG = "00000000000011000011000001000100" *) (* C_SEL_WIDTH = "0" *) 
(* C_TEST_CORE = "0" *) (* C_VERBOSITY = "0" *) (* C_XDEVICEFAMILY = "zynq" *) 
(* ORIG_REF_NAME = "xbip_dsp48_macro_v3_0_15" *) (* downgradeipidentifiedwarnings = "yes" *) 
module xbip_dsp48_macro_0_xbip_dsp48_macro_v3_0_15
   (CLK,
    CE,
    SCLR,
    SEL,
    CARRYCASCIN,
    CARRYIN,
    PCIN,
    ACIN,
    BCIN,
    A,
    B,
    C,
    D,
    CONCAT,
    ACOUT,
    BCOUT,
    CARRYOUT,
    CARRYCASCOUT,
    PCOUT,
    P,
    CED,
    CED1,
    CED2,
    CED3,
    CEA,
    CEA1,
    CEA2,
    CEA3,
    CEA4,
    CEB,
    CEB1,
    CEB2,
    CEB3,
    CEB4,
    CECONCAT,
    CECONCAT3,
    CECONCAT4,
    CECONCAT5,
    CEC,
    CEC1,
    CEC2,
    CEC3,
    CEC4,
    CEC5,
    CEM,
    CEP,
    CESEL,
    CESEL1,
    CESEL2,
    CESEL3,
    CESEL4,
    CESEL5,
    SCLRD,
    SCLRA,
    SCLRB,
    SCLRCONCAT,
    SCLRC,
    SCLRM,
    SCLRP,
    SCLRSEL);
  input CLK;
  input CE;
  input SCLR;
  input [0:0]SEL;
  input CARRYCASCIN;
  input CARRYIN;
  input [47:0]PCIN;
  input [29:0]ACIN;
  input [17:0]BCIN;
  input [23:0]A;
  input [7:0]B;
  input [47:0]C;
  input [17:0]D;
  input [47:0]CONCAT;
  output [29:0]ACOUT;
  output [17:0]BCOUT;
  output CARRYOUT;
  output CARRYCASCOUT;
  output [47:0]PCOUT;
  output [31:0]P;
  input CED;
  input CED1;
  input CED2;
  input CED3;
  input CEA;
  input CEA1;
  input CEA2;
  input CEA3;
  input CEA4;
  input CEB;
  input CEB1;
  input CEB2;
  input CEB3;
  input CEB4;
  input CECONCAT;
  input CECONCAT3;
  input CECONCAT4;
  input CECONCAT5;
  input CEC;
  input CEC1;
  input CEC2;
  input CEC3;
  input CEC4;
  input CEC5;
  input CEM;
  input CEP;
  input CESEL;
  input CESEL1;
  input CESEL2;
  input CESEL3;
  input CESEL4;
  input CESEL5;
  input SCLRD;
  input SCLRA;
  input SCLRB;
  input SCLRCONCAT;
  input SCLRC;
  input SCLRM;
  input SCLRP;
  input SCLRSEL;

  wire [23:0]A;
  wire [29:0]ACIN;
  wire [29:0]ACOUT;
  wire [7:0]B;
  wire [17:0]BCIN;
  wire [17:0]BCOUT;
  wire CARRYCASCIN;
  wire CARRYCASCOUT;
  wire CARRYIN;
  wire CARRYOUT;
  wire CLK;
  wire [31:0]P;
  wire [47:0]PCIN;
  wire [47:0]PCOUT;

  (* C_A_WIDTH = "24" *) 
  (* C_B_WIDTH = "8" *) 
  (* C_CONCAT_WIDTH = "48" *) 
  (* C_CONSTANT_1 = "1" *) 
  (* C_C_WIDTH = "48" *) 
  (* C_D_WIDTH = "18" *) 
  (* C_HAS_A = "1" *) 
  (* C_HAS_ACIN = "0" *) 
  (* C_HAS_ACOUT = "0" *) 
  (* C_HAS_B = "1" *) 
  (* C_HAS_BCIN = "0" *) 
  (* C_HAS_BCOUT = "0" *) 
  (* C_HAS_C = "0" *) 
  (* C_HAS_CARRYCASCIN = "0" *) 
  (* C_HAS_CARRYCASCOUT = "0" *) 
  (* C_HAS_CARRYIN = "0" *) 
  (* C_HAS_CARRYOUT = "0" *) 
  (* C_HAS_CE = "0" *) 
  (* C_HAS_CEA = "0" *) 
  (* C_HAS_CEB = "0" *) 
  (* C_HAS_CEC = "0" *) 
  (* C_HAS_CECONCAT = "0" *) 
  (* C_HAS_CED = "0" *) 
  (* C_HAS_CEM = "0" *) 
  (* C_HAS_CEP = "0" *) 
  (* C_HAS_CESEL = "0" *) 
  (* C_HAS_CONCAT = "0" *) 
  (* C_HAS_D = "0" *) 
  (* C_HAS_INDEP_CE = "0" *) 
  (* C_HAS_INDEP_SCLR = "0" *) 
  (* C_HAS_PCIN = "0" *) 
  (* C_HAS_PCOUT = "0" *) 
  (* C_HAS_SCLR = "0" *) 
  (* C_HAS_SCLRA = "0" *) 
  (* C_HAS_SCLRB = "0" *) 
  (* C_HAS_SCLRC = "0" *) 
  (* C_HAS_SCLRCONCAT = "0" *) 
  (* C_HAS_SCLRD = "0" *) 
  (* C_HAS_SCLRM = "0" *) 
  (* C_HAS_SCLRP = "0" *) 
  (* C_HAS_SCLRSEL = "0" *) 
  (* C_LATENCY = "-1" *) 
  (* C_MODEL_TYPE = "0" *) 
  (* C_OPMODES = "000100100000010100000000" *) 
  (* C_P_LSB = "0" *) 
  (* C_P_MSB = "31" *) 
  (* C_REG_CONFIG = "00000000000011000011000001000100" *) 
  (* C_SEL_WIDTH = "0" *) 
  (* C_TEST_CORE = "0" *) 
  (* C_VERBOSITY = "0" *) 
  (* C_XDEVICEFAMILY = "zynq" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  xbip_dsp48_macro_0_xbip_dsp48_macro_v3_0_15_viv i_synth
       (.A(A),
        .ACIN(ACIN),
        .ACOUT(ACOUT),
        .B(B),
        .BCIN(BCIN),
        .BCOUT(BCOUT),
        .C({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .CARRYCASCIN(CARRYCASCIN),
        .CARRYCASCOUT(CARRYCASCOUT),
        .CARRYIN(CARRYIN),
        .CARRYOUT(CARRYOUT),
        .CE(1'b0),
        .CEA(1'b0),
        .CEA1(1'b0),
        .CEA2(1'b0),
        .CEA3(1'b0),
        .CEA4(1'b0),
        .CEB(1'b0),
        .CEB1(1'b0),
        .CEB2(1'b0),
        .CEB3(1'b0),
        .CEB4(1'b0),
        .CEC(1'b0),
        .CEC1(1'b0),
        .CEC2(1'b0),
        .CEC3(1'b0),
        .CEC4(1'b0),
        .CEC5(1'b0),
        .CECONCAT(1'b0),
        .CECONCAT3(1'b0),
        .CECONCAT4(1'b0),
        .CECONCAT5(1'b0),
        .CED(1'b0),
        .CED1(1'b0),
        .CED2(1'b0),
        .CED3(1'b0),
        .CEM(1'b0),
        .CEP(1'b0),
        .CESEL(1'b0),
        .CESEL1(1'b0),
        .CESEL2(1'b0),
        .CESEL3(1'b0),
        .CESEL4(1'b0),
        .CESEL5(1'b0),
        .CLK(CLK),
        .CONCAT({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .D({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .P(P),
        .PCIN(PCIN),
        .PCOUT(PCOUT),
        .SCLR(1'b0),
        .SCLRA(1'b0),
        .SCLRB(1'b0),
        .SCLRC(1'b0),
        .SCLRCONCAT(1'b0),
        .SCLRD(1'b0),
        .SCLRM(1'b0),
        .SCLRP(1'b0),
        .SCLRSEL(1'b0),
        .SEL(1'b0));
endmodule
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2015"
`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="cds_rsa_key", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=64)
`pragma protect key_block
nBlnHi3Kp5ztG6vZNdMONLkWpVVpg2r7ZP2rdZEfioM4XUkRew1oDSrAozd60ivTx8PLiOPPRAJo
pOZd0llK5g==

`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
Kcs1MQe5BgqnN7tbrZMcEiZZSCl175bCFWu5jwqWj4RFDG/n9GjuiwAuZ9v2vQZcAxVE3h5w+TBc
Bk1lc9zc7T3tnbm4qpXepckPAqiTqMURQNO28XRRz5BSiTktDkY/dUGVSA0qxTdPGlkYZSpuFpl6
PjievZtLxEtp4cSEwJE=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
aG1w9h5Ae0N98iRQuCMUHQUwBA2KqP2Fbb/SCJOtosbKahOePVIWiIrkhbLMsr1/omYs/Q6fEj2G
uYHIEBLZLRANmjJt9kQu/jIzWAf0nK3OJkUCAMefyflw5y403PkpWIAHXqlArlaCVW2gWxzVxt9G
js0j3l7Y2dpahAMg2LgLgWyMj2rS0kjr+fbTwgci9As5Ndo6CDyXo7EcixOTvkWvqwxJaYFbtcFF
K1j0WC1jYCLSiEJ2ZB5/ODVnSmn3AWSksydgQ3iYMKpYPNlAwFN7t7HacZ95HxO8MGoNyjnDje35
EzrNZrAA4vUP8Y6En1JgkF6RLt8PJJfLc+wq+g==

`pragma protect key_keyowner="ATRENTA", key_keyname="ATR-SG-2015-RSA-3", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
BYWKn+AL7Gth8aEXuzL+rpOrNP6Ug8Hc9TpmOLZLrPZ4boPFPd89qpRHOY6mfox3M09mZK4TuSx+
5DykxgtH7Gu2DHCqtg3Tg7eFTAzurR/EqXoPhuHQIzs5Y1T/5WlIb0c4l9CNWdc5TBVfbmKR+x4N
A259tw/6q69OtmAqFiB+p9GY8lyjNDWu07DJlxI2l6wSRYy8YqD7K1OrLRXxY6gaTqDWDXlcO+ia
T5/harPHjTiNAFO8U6YTfRQtNJUrOnNfSAnAtjrlegYGNcEl6u4sqYE/X/Pajk2n+1+KvJ6PR8L9
bdrCByV81f1z88nc1Twl6LUe54VQdfe5W+EOpQ==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2017_05", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
iJnLIMkUEl7Btn7IVUeqK6xbyk9c7fsISctkfj2c6osS1GvgHXWHkJPpNPHTeIth7zUvkUlYB/Jd
M5kNK3leJJj5TaqOLOh+cyWqEGY64EruHImVJasbLaVn3LUh67wEEMFoKhP9/KjqLsL3oFrKnU4i
JzYtVgZoCfaHBaIyRC6wms7z/YKP2Khya0dzmYHMmbdm9k2rL27fVLJcCEMSO1Dsz2D/qXnCFI8T
NHnM3Fv/xF2jOhtDIDqWGakvXk7l+ddg95MJ+5A578jqVX81M0WJwbHlaIJIG5uwIzTI46+pYw0Z
4sgDMkrl/aXSFYB5PU2L4hhVeq7e6c0dqUOVSw==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
sdiBszQspScY+UIwuaohSbs1PAZL6bemuOZlFLGklUXNsz7r1265PlclnSy9m0ilIWxY0HJkGEtl
Rs/zfRlF9Ag/CEiBQ4lStxiXa4cbOvNwkp9j1BXCYCAbMsw83x+ZvpyoQTXRfcBBvSAbtpFDJ7ar
qlJbO6erRjpDP373GIY=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
eUV1ae8Aw6l0UtyVDuKmrMQwdVI8vrJTYSKwNJ+/x3fs7qy5B2fVzNE8tFRcie7NykwBpJV9lQNN
iNNcReVBjS/oh7txKer0RVLuw2jQCeQBSixWXwdIra9CsrIF5V2GUuY3dDh9ofaqsgbKSlDNLzzm
0lHhjAw4Nbk9kwoo5NP9xZYaLPCNo4Qqi0A9Px++Zu3V7DcbPDDDQnNEzgQhcN8ilscDyGVOeiHu
/xJbo1lLkpyrDciztvHYqwj9O/kSyF1PikDg8xEaOx1QQVvaz7r51DlXlPCpqCUyFGEeiIrPCMHf
8rf7t9DpvBEVPF3eaofCDfiW9vWmbfgffwtMYg==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-PREC-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
plmbY0zb/UPWUC3m46XR58lwI8FZ4OuFIQFWIU+CxQ3LnTAsA/wH49bY2XvPJEjRxkStTl4+/qql
txA2F7/xHDYYmtdVbR8Len+VOq+A5gSQNMS6Uf7N8ZepXPKwqiwOr+IR9WVSTA9RSPmTVQ3W7C59
2nOPEw7kCOe487DIqs7sUtyJ36jSeenl+rGY2iduqxchIi23kF3P8ilPVfpPG+qbTxMIQsnc5qi+
aZuAB4sV9GpJowk8b/vSmRLasqLNor40Kes8UMfZwS8XQqwG8H/nvwyyIQ0LNZ/PEp4XwzwM7GUf
2OPt2c8YMhZXweDxMr9KUMUJNDHd2tzFbnNxfw==

`pragma protect key_keyowner="Synplicity", key_keyname="SYNP15_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Rvltl+obBaOpW25QjtErdn7bRetk/G1zKUxZ2ogxPVF5n4wMtUh6XiIxz/W7rMYJo2tNe2ztttNV
IUCzQ2bVLekzXF1tgvxCIVmZgcsSWMIW56H5+vIipz3re3WKN2aW2pIE3w+6BH+GWeyGCNmMbLTK
sNw9ij9R36KxJQsRTAg0QwC98vC/8M1vFxK0+YR/BF25PWhbJk1Ku3VCToLr7jP7Dhv33TAFBh19
vpWBENBZzmt2pYGH8BoPKExySi67E0OJluVfyeZqWRLXxXKxNiePwJZbs/d3uCJqPdi1971b+RrU
Bg1Md0neDHZwY1KMVGUzL714e57IvsHDOIvymA==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 30144)
`pragma protect data_block
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
`pragma protect end_protected
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

endmodule
`endif
