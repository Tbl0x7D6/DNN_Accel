`timescale 1ns / 1ps

module Executor_tb;

    parameter DATA_WIDTH = 8;
    parameter ACC_WIDTH = 26;
    parameter PE_ACC_WIDTH = 21;

    logic clk;
    logic rst_n;
    logic [63:0] instruction;
    logic done;

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


    Executor #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .PE_ACC_WIDTH(PE_ACC_WIDTH)
    ) executor_inst (
        .clk(clk),
        .rst_n(rst_n),
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
        .done(done)
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
        .wea                     (ifm_wr_en),
        .addra                   (ifm_addr),
        .dina                    (ifm_wr_data),
        .injectsbiterra          (1'b0),
        .injectdbiterra          (1'b0),
        .douta                   (ifm_rd_data),
        .sbiterra                (),
        .dbiterra                ()

    );


    xpm_memory_spram # (

        // Common module parameters
        .MEMORY_SIZE             (DATA_WIDTH*16*16384),            //positive integer
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
        .ADDR_WIDTH_A            (14),               //positive integer
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



    logic signed [DATA_WIDTH-1:0] ifm_mem [0:2048*16-1]; 
    logic signed [DATA_WIDTH-1:0] wgt_mem [0:16384*16-1];
    logic signed [7:0] golden_mem [0:2048*16-1];

    logic [7:0] img_size;
    logic [7:0] out_size;
    logic [3:0] ifm_channel_tiles;
    logic [3:0] ofm_channel_tiles;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    integer i, j, k, l, m;
    integer idx;

    initial begin
        $readmemh("c:/Users/be/Desktop/DNN_Accel/Test_Generator/data/ifm.txt", ifm_mem);
        $readmemh("c:/Users/be/Desktop/DNN_Accel/Test_Generator/data/weights.txt", wgt_mem);
        $readmemh("c:/Users/be/Desktop/DNN_Accel/Test_Generator/data/golden_5.txt", golden_mem);

        img_size = 32;
        ifm_channel_tiles = 1;

        for (i = 0; i < img_size; i = i + 1) begin
            for (j = 0; j < img_size; j = j + 1) begin
                for (k = 0; k < ifm_channel_tiles; k = k + 1) begin
                    logic [DATA_WIDTH*16-1:0] tmp_ifm;
                    idx = (i * img_size + j) * ifm_channel_tiles + k;
                    for (l = 0; l < 16; l = l + 1) begin
                        tmp_ifm[l*DATA_WIDTH +: DATA_WIDTH] = ifm_mem[idx * 16 + l];
                    end
                    ifm_bram_inst.xpm_memory_base_inst.mem[idx] = tmp_ifm;
                end
            end
        end
        for (i = 0; i < 8992; i++) begin
            logic [DATA_WIDTH*16-1:0] tmp_weight;
            for (j = 0; j < 16; j = j + 1) begin
                tmp_weight[j*DATA_WIDTH +: DATA_WIDTH] = wgt_mem[i * 16 + j];
            end
            weight_bram_inst.xpm_memory_base_inst.mem[i] = tmp_weight;
        end
        for (i = 0; i < 2048; i = i + 1) begin
            output_bram_inst.xpm_memory_base_inst.mem[i] = 0;
        end

        // instruction = 64'h0109000020561020;
        instruction = 64'h0109000020562012;

        rst_n = 0;
        #100;
        rst_n = 1;
        wait(done);

        // instruction = 64'h1000000020282020;
        instruction = 64'h1000000020281022;

        rst_n = 0;
        #100;
        rst_n = 1;
        wait(done);
        #100;

        // instruction = 64'h0108032010352040;
        instruction = 64'h0108032010351024;

        rst_n = 0;
        #100;
        rst_n = 1;
        wait(done);
        #100;

        // instruction = 64'h010807A010394040;
        instruction = 64'h010807A010390844;

        rst_n = 0;
        #100;
        rst_n = 1;
        wait(done);
        #100;

        // instruction = 64'h010810A008394080;
        instruction = 64'h010810A008390448;

        rst_n = 0;
        #100;
        rst_n = 1;
        wait(done);
        #100;

        // instruction = 64'h3004000004448080;
        instruction = 64'h3004000004440188;

        rst_n = 0;
        #100;
        rst_n = 1;
        wait(done);
        #100;

        // instruction = 64'h000622A001148010;
        instruction = 64'h000622A001140181;

        rst_n = 0;
        #100;
        rst_n = 1;
        wait(done);
        #100;

        $display("Simulation Finished.");

        out_size = 1;
        ofm_channel_tiles = 1;

        for (i = 0; i < out_size; i = i + 1) begin
            for (j = 0; j < out_size; j = j + 1) begin
                for (k = 0; k < ofm_channel_tiles; k = k + 1) begin
                    logic signed [127:0] dut_output;
                    idx = (i * out_size + j) * ofm_channel_tiles + k;
                    dut_output = ifm_bram_inst.xpm_memory_base_inst.mem[idx];
                    for (l = 0; l < 16; l = l + 1) begin
                        logic signed [7:0] dut_val;
                        dut_val = $signed(dut_output[l*8 +: 8]);
                        $display("Checking OFM(%0d,%0d,%0d): DUT=%0d, GOLDEN=%0d",
                                 i, j, k * 16 + l, dut_val, golden_mem[idx * 16 + l]);
                        if (dut_val !== golden_mem[idx * 16 + l]) begin
                            $display("Mismatch at OFM(%0d,%0d,%0d): DUT=%0d, GOLDEN=%0d",
                                    i, j, k * 16 + l, dut_val, golden_mem[idx * 16 + l]);
                            $finish;
                        end
                    end
                end
            end
        end

        $finish;
    end

endmodule
