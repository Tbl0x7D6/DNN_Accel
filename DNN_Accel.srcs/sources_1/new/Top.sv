`timescale 1ns / 1ps

module Top #(
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

    logic [DATA_WIDTH*16-1:0] ifm_data;
    logic [15:0]              ifm_addr;

    logic [DATA_WIDTH*16-1:0] filter_data;
    logic [15:0]              filter_addr;

    logic [ACC_WIDTH *16-1:0] ofm_rd_data;
    logic [15:0]              ofm_rd_addr;
    logic [ACC_WIDTH *16-1:0] ofm_wr_data;
    logic [15:0]              ofm_wr_addr;
    logic                     ofm_wr_en;

    Layer #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .PE_ACC_WIDTH(PE_ACC_WIDTH)
    ) layer_inst (
        .clk(clk),
        .rst_n(rst_n),
        .img_size(img_size),
        .k_size(k_size),
        .stride(stride),
        .padding(padding),
        .ifm_channels(ifm_channels),
        .ofm_channels(ofm_channels),
        .done(done),
        .ifm_data(ifm_data),
        .ifm_addr(ifm_addr),
        .filter_data(filter_data),
        .filter_addr(filter_addr),
        .ofm_rd_data(ofm_rd_data),
        .ofm_rd_addr(ofm_rd_addr),
        .ofm_wr_data(ofm_wr_data),
        .ofm_wr_addr(ofm_wr_addr),
        .ofm_wr_en(ofm_wr_en)
    );

    xpm_memory_spram # (

        // Common module parameters
        .MEMORY_SIZE             (DATA_WIDTH*16*2048),            //positive integer
        .MEMORY_PRIMITIVE        ("auto"),          //string; "auto", "distributed", "block" or "ultra";
        .MEMORY_INIT_FILE        ("none"),          //string; "none" or "<filename>.mem" 
        .MEMORY_INIT_PARAM       (""    ),          //string;
        .USE_MEM_INIT            (0),               //integer; 0,1
        .WAKEUP_TIME             ("disable_sleep"), //string; "disable_sleep" or "use_sleep_pin" 
        .MESSAGE_CONTROL         (0),               //integer; 0,1
        .MEMORY_OPTIMIZATION     ("true"),          //string; "true", "false" 

        // Port A module parameters
        .WRITE_DATA_WIDTH_A      (DATA_WIDTH*16),              //positive integer
        .READ_DATA_WIDTH_A       (DATA_WIDTH*16),              //positive integer
        .BYTE_WRITE_WIDTH_A      (DATA_WIDTH*16),              //integer; 8, 9, or WRITE_DATA_WIDTH_A value
        .ADDR_WIDTH_A            (11),               //positive integer
        .READ_RESET_VALUE_A      ("0"),             //string
        .ECC_MODE                ("no_ecc"),        //string; "no_ecc", "encode_only", "decode_only" or "both_encode_and_decode" 
        .AUTO_SLEEP_TIME         (0),               //Do not Change
        .READ_LATENCY_A          (1),               //non-negative integer
        .WRITE_MODE_A            ("read_first")     //string; "write_first", "read_first", "no_change" 

    ) ifm_bram_inst (

        // Common module ports
        .sleep                   (1'b0),

        // Port A module ports
        .clka                    (clk),
        .rsta                    (~rst_n),
        .ena                     (1),
        .regcea                  (),
        .wea                     (0),
        .addra                   (ifm_addr),
        .dina                    ({DATA_WIDTH*16{1'b0}}),
        .injectsbiterra          (1'b0),
        .injectdbiterra          (1'b0),
        .douta                   (ifm_data),
        .sbiterra                (),
        .dbiterra                ()

    );


    xpm_memory_spram # (

        // Common module parameters
        .MEMORY_SIZE             (DATA_WIDTH*16*4608),            //positive integer
        .MEMORY_PRIMITIVE        ("auto"),          //string; "auto", "distributed", "block" or "ultra";
        .MEMORY_INIT_FILE        ("none"),          //string; "none" or "<filename>.mem" 
        .MEMORY_INIT_PARAM       (""    ),          //string;
        .USE_MEM_INIT            (0),               //integer; 0,1
        .WAKEUP_TIME             ("disable_sleep"), //string; "disable_sleep" or "use_sleep_pin" 
        .MESSAGE_CONTROL         (0),               //integer; 0,1
        .MEMORY_OPTIMIZATION     ("true"),          //string; "true", "false" 

        // Port A module parameters
        .WRITE_DATA_WIDTH_A      (DATA_WIDTH*16),              //positive integer
        .READ_DATA_WIDTH_A       (DATA_WIDTH*16),              //positive integer
        .BYTE_WRITE_WIDTH_A      (DATA_WIDTH*16),              //integer; 8, 9, or WRITE_DATA_WIDTH_A value
        .ADDR_WIDTH_A            (13),               //positive integer
        .READ_RESET_VALUE_A      ("0"),             //string
        .ECC_MODE                ("no_ecc"),        //string; "no_ecc", "encode_only", "decode_only" or "both_encode_and_decode" 
        .AUTO_SLEEP_TIME         (0),               //Do not Change
        .READ_LATENCY_A          (1),               //non-negative integer
        .WRITE_MODE_A            ("read_first")     //string; "write_first", "read_first", "no_change" 

    ) weight_bram_inst (

        // Common module ports
        .sleep                   (1'b0),

        // Port A module ports
        .clka                    (clk),
        .rsta                    (~rst_n),
        .ena                     (1),
        .regcea                  (),
        .wea                     (0),
        .addra                   (filter_addr),
        .dina                    ({DATA_WIDTH*16{1'b0}}),
        .injectsbiterra          (1'b0),
        .injectdbiterra          (1'b0),
        .douta                   (filter_data),
        .sbiterra                (),
        .dbiterra                ()

    );

    xpm_memory_sdpram # (

        // Common module parameters
        .MEMORY_SIZE             (ACC_WIDTH*16*2048),            //positive integer
        .MEMORY_PRIMITIVE        ("auto"),          //string; "auto", "distributed", "block" or "ultra";
        .CLOCKING_MODE           ("common_clock"),  //string; "common_clock", "independent_clock" 
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
        .WRITE_DATA_WIDTH_A      (ACC_WIDTH*16),              //positive integer
        .BYTE_WRITE_WIDTH_A      (ACC_WIDTH*16),              //integer; 8, 9, or WRITE_DATA_WIDTH_A value
        .ADDR_WIDTH_A            (11),               //positive integer

        // Port B module parameters
        .READ_DATA_WIDTH_B       (ACC_WIDTH*16),              //positive integer
        .ADDR_WIDTH_B            (11),               //positive integer
        .READ_RESET_VALUE_B      ("0"),             //string
        .READ_LATENCY_B          (1),               //non-negative integer
        .WRITE_MODE_B            ("no_change")      //string; "write_first", "read_first", "no_change" 

    ) output_bram_inst (

        // Common module ports
        .sleep                   (1'b0),

        // Port A module ports
        .clka                    (clk),
        .ena                     (1),
        .wea                     (ofm_wr_en),
        .addra                   (ofm_wr_addr),
        .dina                    (ofm_wr_data),
        .injectsbiterra          (1'b0),
        .injectdbiterra          (1'b0),

        // Port B module ports
        .clkb                    (clk),
        .rstb                    (~rst_n),
        .enb                     (1),
        .regceb                  (),
        .addrb                   (ofm_rd_addr),
        .doutb                   (ofm_rd_data),
        .sbiterrb                (),
        .dbiterrb                ()

    );

endmodule
