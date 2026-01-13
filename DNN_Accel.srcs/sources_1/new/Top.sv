`timescale 1ns / 1ps

module Top (
    input logic clk,
    input logic rst_n,
    input logic start,
    output logic done,

    // ---- AXI BRAM Controller Interface ----
    input  logic         axi_ifm_clk,
    input  logic         axi_ifm_rst,
    input  logic         axi_ifm_en,
    input  logic [15:0]  axi_ifm_wr_en,
    input  logic [14:0]  axi_ifm_addr,
    input  logic [127:0] axi_ifm_wr_data,
    output logic [127:0] axi_ifm_rd_data,

    input  logic         axi_filter_clk,
    input  logic         axi_filter_rst,
    input  logic         axi_filter_en,
    input  logic [15:0]  axi_filter_wr_en,
    input  logic [17:0]  axi_filter_addr,
    input  logic [127:0] axi_filter_wr_data,
    output logic [127:0] axi_filter_rd_data,

    input  logic         axi_inst_clk,
    input  logic         axi_inst_rst,
    input  logic         axi_inst_en,
    input  logic [7:0]   axi_inst_wr_en,
    input  logic [11:0]  axi_inst_addr,
    input  logic [63:0]  axi_inst_wr_data,
    output logic [63:0]  axi_inst_rd_data
);

    parameter DATA_WIDTH = 8;
    parameter ACC_WIDTH = 26;
    parameter PE_ACC_WIDTH = 21;

    logic [DATA_WIDTH*16-1:0] ifm_rd_data;
    logic [DATA_WIDTH*16-1:0] ifm_wr_data;
    logic [15:0]              ifm_addr;
    logic                     ifm_wr_en;

    logic [DATA_WIDTH*16-1:0] filter_data;
    logic [15:0]              filter_addr;

    logic [ACC_WIDTH *16-1:0] ofm_rd_data;
    logic [ACC_WIDTH *16-1:0] ofm_wr_data;
    logic [15:0]              ofm_rd_addr;
    logic [15:0]              ofm_wr_addr;
    logic                     ofm_wr_en;


    logic [63:0] instruction;
    logic exec_rst_n;
    logic exec_done;

    Executor #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .PE_ACC_WIDTH(PE_ACC_WIDTH)
    ) executor_inst (
        .clk(clk),
        .rst_n(exec_rst_n),
        .instruction(instruction),
        .ifm_rd_data(ifm_rd_data),
        .ifm_wr_data(ifm_wr_data),
        .ifm_addr(ifm_addr),
        .ifm_wr_en(ifm_wr_en),
        .filter_data(filter_data),
        .filter_addr(filter_addr),
        .ofm_rd_data(ofm_rd_data),
        .ofm_wr_data(ofm_wr_data),
        .ofm_rd_addr(ofm_rd_addr),
        .ofm_wr_addr(ofm_wr_addr),
        .ofm_wr_en(ofm_wr_en),
        .done(exec_done)
    );


    xpm_memory_tdpram # (

        // Common module parameters
        .MEMORY_SIZE             (DATA_WIDTH*16*2048),            //positive integer
        .MEMORY_PRIMITIVE        ("auto"),          //string; "auto", "distributed", "block" or "ultra";
        .CLOCKING_MODE           ("independent_clock"),  //string; "common_clock", "independent_clock"
        .MEMORY_INIT_FILE        ("none"),          //string; "none" or "<filename>.mem"
        .MEMORY_INIT_PARAM       (""    ),          //string;
        .USE_MEM_INIT            (1),               //integer; 0,1
        .WAKEUP_TIME             ("disable_sleep"), //string; "disable_sleep" or "use_sleep_pin"
        .MESSAGE_CONTROL         (0),               //integer; 0,1
        .ECC_MODE                ("no_ecc"),        //string; "no_ecc", "encode_only", "decode_only" or "both_encode_and_decode"
        .AUTO_SLEEP_TIME         (0),               //Do not Change
        .USE_EMBEDDED_CONSTRAINT (0),               //integer: 0,1
        .MEMORY_OPTIMIZATION     ("true"),          //string; "true", "false"

        // Port A module parameters
        .WRITE_DATA_WIDTH_A      (DATA_WIDTH*16),              //positive integer
        .READ_DATA_WIDTH_A       (DATA_WIDTH*16),              //positive integer
        .BYTE_WRITE_WIDTH_A      (DATA_WIDTH*16),              //integer; 8, 9, or WRITE_DATA_WIDTH_A value
        .ADDR_WIDTH_A            (11),               //positive integer
        .READ_RESET_VALUE_A      ("0"),             //string
        .READ_LATENCY_A          (1),               //non-negative integer
        .WRITE_MODE_A            ("read_first"),     //string; "write_first", "read_first", "no_change"

        // Port B module parameters
        .WRITE_DATA_WIDTH_B      (DATA_WIDTH*16),              //positive integer
        .READ_DATA_WIDTH_B       (DATA_WIDTH*16),              //positive integer
        .BYTE_WRITE_WIDTH_B      (8),              //integer; 8, 9, or WRITE_DATA_WIDTH_B value
        .ADDR_WIDTH_B            (11),               //positive integer
        .READ_RESET_VALUE_B      ("0"),             //vector of READ_DATA_WIDTH_B bits
        .READ_LATENCY_B          (1),               //non-negative integer
        .WRITE_MODE_B            ("no_change")      //string; "write_first", "read_first", "no_change"

    ) ifm_bram_inst (

        // Common module ports
        .sleep                   (1'b0),

        // Port A module ports
        .clka                    (clk),
        .rsta                    (~rst_n),
        .ena                     (1),
        .regcea                  (),
        .wea                     (ifm_wr_en),
        .addra                   (ifm_addr),
        .dina                    (ifm_wr_data),
        .injectsbiterra          (1'b0),
        .injectdbiterra          (1'b0),
        .douta                   (ifm_rd_data),
        .sbiterra                (),
        .dbiterra                (),

        // Port B module ports
        .clkb                    (axi_ifm_clk),
        .rstb                    (axi_ifm_rst),
        .enb                     (axi_ifm_en),
        .regceb                  (),
        .web                     (axi_ifm_wr_en),
        .addrb                   (axi_ifm_addr[14:4]),
        .dinb                    (axi_ifm_wr_data),
        .injectsbiterrb          (1'b0),
        .injectdbiterrb          (1'b0),
        .doutb                   (axi_ifm_rd_data),
        .sbiterrb                (),
        .dbiterrb                ()

    );


    xpm_memory_tdpram # (

        // Common module parameters
        .MEMORY_SIZE             (DATA_WIDTH*16*16384),            //positive integer
        .MEMORY_PRIMITIVE        ("auto"),          //string; "auto", "distributed", "block" or "ultra";
        .CLOCKING_MODE           ("independent_clock"),  //string; "common_clock", "independent_clock"
        .MEMORY_INIT_FILE        ("none"),          //string; "none" or "<filename>.mem"
        .MEMORY_INIT_PARAM       (""    ),          //string;
        .USE_MEM_INIT            (1),               //integer; 0,1
        .WAKEUP_TIME             ("disable_sleep"), //string; "disable_sleep" or "use_sleep_pin"
        .MESSAGE_CONTROL         (0),               //integer; 0,1
        .ECC_MODE                ("no_ecc"),        //string; "no_ecc", "encode_only", "decode_only" or "both_encode_and_decode"
        .AUTO_SLEEP_TIME         (0),               //Do not Change
        .USE_EMBEDDED_CONSTRAINT (0),               //integer: 0,1
        .MEMORY_OPTIMIZATION     ("true"),          //string; "true", "false"

        // Port A module parameters
        .WRITE_DATA_WIDTH_A      (DATA_WIDTH*16),              //positive integer
        .READ_DATA_WIDTH_A       (DATA_WIDTH*16),              //positive integer
        .BYTE_WRITE_WIDTH_A      (DATA_WIDTH*16),              //integer; 8, 9, or WRITE_DATA_WIDTH_A value
        .ADDR_WIDTH_A            (14),               //positive integer
        .READ_RESET_VALUE_A      ("0"),             //string
        .READ_LATENCY_A          (1),               //non-negative integer
        .WRITE_MODE_A            ("read_first"),     //string; "write_first", "read_first", "no_change"

        // Port B module parameters
        .WRITE_DATA_WIDTH_B      (DATA_WIDTH*16),              //positive integer
        .READ_DATA_WIDTH_B       (DATA_WIDTH*16),              //positive integer
        .BYTE_WRITE_WIDTH_B      (8),              //integer; 8, 9, or WRITE_DATA_WIDTH_B value
        .ADDR_WIDTH_B            (14),               //positive integer
        .READ_RESET_VALUE_B      ("0"),             //vector of READ_DATA_WIDTH_B bits
        .READ_LATENCY_B          (1),               //non-negative integer
        .WRITE_MODE_B            ("no_change")      //string; "write_first", "read_first", "no_change"

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
        .dbiterra                (),

        // Port B module ports
        .clkb                    (axi_filter_clk),
        .rstb                    (axi_filter_rst),
        .enb                     (axi_filter_en),
        .regceb                  (),
        .web                     (axi_filter_wr_en),
        .addrb                   (axi_filter_addr[17:4]),
        .dinb                    (axi_filter_wr_data),
        .injectsbiterrb          (1'b0),
        .injectdbiterrb          (1'b0),
        .doutb                   (axi_filter_rd_data),
        .sbiterrb                (),
        .dbiterrb                ()

    );


    xpm_memory_sdpram # (

        // Common module parameters
        .MEMORY_SIZE             (ACC_WIDTH*16*2048),            //positive integer
        .MEMORY_PRIMITIVE        ("auto"),          //string; "auto", "distributed", "block" or "ultra";
        .CLOCKING_MODE           ("common_clock"),  //string; "common_clock", "independent_clock"
        .MEMORY_INIT_FILE        ("none"),          //string; "none" or "<filename>.mem"
        .MEMORY_INIT_PARAM       (""    ),          //string;
        .USE_MEM_INIT            (1),               //integer; 0,1
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


    logic [8:0] pc;

    xpm_memory_tdpram # (

        // Common module parameters
        .MEMORY_SIZE             (64*512),            //positive integer
        .MEMORY_PRIMITIVE        ("auto"),          //string; "auto", "distributed", "block" or "ultra";
        .CLOCKING_MODE           ("independent_clock"),  //string; "common_clock", "independent_clock"
        .MEMORY_INIT_FILE        ("none"),          //string; "none" or "<filename>.mem"
        .MEMORY_INIT_PARAM       (""    ),          //string;
        .USE_MEM_INIT            (1),               //integer; 0,1
        .WAKEUP_TIME             ("disable_sleep"), //string; "disable_sleep" or "use_sleep_pin"
        .MESSAGE_CONTROL         (0),               //integer; 0,1
        .ECC_MODE                ("no_ecc"),        //string; "no_ecc", "encode_only", "decode_only" or "both_encode_and_decode"
        .AUTO_SLEEP_TIME         (0),               //Do not Change
        .USE_EMBEDDED_CONSTRAINT (0),               //integer: 0,1
        .MEMORY_OPTIMIZATION     ("true"),          //string; "true", "false"

        // Port A module parameters
        .WRITE_DATA_WIDTH_A      (64),              //positive integer
        .READ_DATA_WIDTH_A       (64),              //positive integer
        .BYTE_WRITE_WIDTH_A      (64),              //integer; 8, 9, or WRITE_DATA_WIDTH_A value
        .ADDR_WIDTH_A            (9),               //positive integer
        .READ_RESET_VALUE_A      ("0"),             //string
        .READ_LATENCY_A          (1),               //non-negative integer
        .WRITE_MODE_A            ("read_first"),     //string; "write_first", "read_first", "no_change"

        // Port B module parameters
        .WRITE_DATA_WIDTH_B      (64),              //positive integer
        .READ_DATA_WIDTH_B       (64),              //positive integer
        .BYTE_WRITE_WIDTH_B      (8),              //integer; 8, 9, or WRITE_DATA_WIDTH_B value
        .ADDR_WIDTH_B            (9),               //positive integer
        .READ_RESET_VALUE_B      ("0"),             //vector of READ_DATA_WIDTH_B bits
        .READ_LATENCY_B          (1),               //non-negative integer
        .WRITE_MODE_B            ("no_change")      //string; "write_first", "read_first", "no_change"

    ) instruction_bram_inst (

        // Common module ports
        .sleep                   (1'b0),

        // Port A module ports
        .clka                    (clk),
        .rsta                    (~rst_n),
        .ena                     (1),
        .regcea                  (),
        .wea                     (0),
        .addra                   (pc),
        .dina                    (0),
        .injectsbiterra          (1'b0),
        .injectdbiterra          (1'b0),
        .douta                   (instruction),
        .sbiterra                (),
        .dbiterra                (),

        // Port B module ports
        .clkb                    (axi_inst_clk),
        .rstb                    (axi_inst_rst),
        .enb                     (axi_inst_en),
        .regceb                  (),
        .web                     (axi_inst_wr_en),
        .addrb                   (axi_inst_addr[11:3]),
        .dinb                    (axi_inst_wr_data),
        .injectsbiterrb          (1'b0),
        .injectdbiterrb          (1'b0),
        .doutb                   (axi_inst_rd_data),
        .sbiterrb                (),
        .dbiterrb                ()

    );


    always_ff @(posedge clk) begin
        if (!rst_n || !start) begin
            pc <= 0;
            done <= 0;
            exec_rst_n <= 0;
        end else if (!done) begin
            if (exec_done && exec_rst_n) begin
                pc <= pc + 1;
                exec_rst_n <= 0;
            end else begin
                exec_rst_n <= 1;
            end

            if (instruction[63] == 1) begin
                done <= 1;
                exec_rst_n <= 0;
            end
        end
    end

endmodule
