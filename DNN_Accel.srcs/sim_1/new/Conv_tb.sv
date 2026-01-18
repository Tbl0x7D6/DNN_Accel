`timescale 1ns / 1ps

module Conv_tb;

    // Parameters
    parameter DATA_WIDTH = 8;
    parameter ACC_WIDTH = 26;
    parameter PE_ACC_WIDTH = 21;
    
    // Clock and Reset
    logic clk;
    logic rst_n;
    logic conv_rst_n;

    // Configuration Inputs
    // Initialize to ensure valid values at time 0 for Layer module initialization
    logic [7:0] img_size = 5;
    logic [3:0] k_size = 3;
    logic [7:0] out_size = 5;
    logic [1:0] stride = 1;
    logic [1:0] padding = 1;

    logic [7:0] ifm_channel_tiles = 4;
    logic [7:0] ofm_channel_tiles = 2;

    logic done;
    
    // Test Data Memories
    logic signed [DATA_WIDTH-1:0] ifm_mem [0:2048*16-1]; 
    logic signed [DATA_WIDTH-1:0] wgt_mem [0:4608*16-1];
    logic signed [31:0] golden_mem [0:2048*16-1];

    logic [DATA_WIDTH*16-1:0] ifm_data;
    logic [15:0]              ifm_addr;
    logic [DATA_WIDTH*16-1:0] ifm_wr_data;
    logic                     ifm_wr_en = 0;

    logic [DATA_WIDTH*16-1:0] filter_data;
    logic [15:0]              filter_addr;

    logic [ACC_WIDTH *16-1:0] ofm_rd_data;
    logic [15:0]              ofm_rd_addr;
    logic [ACC_WIDTH *16-1:0] ofm_wr_data;
    logic [15:0]              ofm_wr_addr;
    logic                     ofm_wr_en;

    Conv #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .PE_ACC_WIDTH(PE_ACC_WIDTH)
    ) layer_inst (
        .clk(clk),
        .rst_n(conv_rst_n),
        .img_size(img_size),
        .k_size(k_size),
        .stride(stride),
        .padding(padding),
        .out_size(out_size),
        .ifm_channel_tiles(ifm_channel_tiles),
        .ofm_channel_tiles(ofm_channel_tiles),
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
        .wea                     (ifm_wr_en),
        .addra                   (ifm_addr),
        .dina                    (ifm_wr_data),
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
    
    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    integer i, j, k, l, m;
    integer idx;
    integer fp;
    
    initial begin
        // 1. Load Files
        // Adjust paths if necessary
        $readmemh("c:/Users/be/Desktop/DNN_Accel/Test_Generator/data/ifm.txt", ifm_mem);
        $readmemh("c:/Users/be/Desktop/DNN_Accel/Test_Generator/data/weights.txt", wgt_mem);
        $readmemh("c:/Users/be/Desktop/DNN_Accel/Test_Generator/data/golden.txt", golden_mem);

        fp = $fopen("c:/Users/be/Desktop/DNN_Accel/Test_Generator/data/config.txt", "r");
        $fscanf(fp, "%d %d %d %d %d %d %d\n", img_size, ifm_channel_tiles, out_size, ofm_channel_tiles, k_size, stride, padding);

        // 2. Initialize DUT Internal Memories
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
        for (idx = 0; idx < k_size * k_size * ifm_channel_tiles * ofm_channel_tiles * 16; idx++) begin
            logic [DATA_WIDTH*16-1:0] tmp_weight;
            for (m = 0; m < 16; m = m + 1) begin
                tmp_weight[m*DATA_WIDTH +: DATA_WIDTH] = wgt_mem[idx * 16 + m]; 
            end
            weight_bram_inst.xpm_memory_base_inst.mem[idx] = tmp_weight;
        end
        for (i = 0; i < 2048; i = i + 1) begin
            output_bram_inst.xpm_memory_base_inst.mem[i] = 0;
        end
        
        // 3. Reset Sequence
        rst_n = 0;
        conv_rst_n = 0;
        #100;
        rst_n = 1;
        conv_rst_n = 1;
        
        // 4. Wait for Completion
        wait(done);
        #100;
        
        $display("Simulation Finished.");
        
        // 5. Check Results
        for (i = 0; i < out_size; i = i + 1) begin
            for (j = 0; j < out_size; j = j + 1) begin
                for (k = 0; k < ofm_channel_tiles; k = k + 1) begin
                    logic signed [ACC_WIDTH*16-1:0] dut_output;
                    idx = (i * out_size + j) * ofm_channel_tiles + k;
                    dut_output = output_bram_inst.xpm_memory_base_inst.mem[idx];
                    for (l = 0; l < 16; l = l + 1) begin
                        logic signed [ACC_WIDTH-1:0] dut_val;
                        dut_val = $signed(dut_output[l*ACC_WIDTH +: ACC_WIDTH]);
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
