`timescale 1ns / 1ps

module PE_Array_tb;

    parameter NUM_ROWS = 32;
    parameter NUM_COLS = 16;
    parameter DATA_WIDTH = 8;
    parameter PE_ACC_WIDTH = 21;

    logic clk;
    logic rst_n;
    logic signed [DATA_WIDTH-1:0]   ifm_in    [0:NUM_ROWS-1];
    logic signed [DATA_WIDTH-1:0]   weight_in [0:NUM_ROWS-1][0:NUM_COLS-1];
    logic signed [PE_ACC_WIDTH-1:0] psum_out  [0:NUM_COLS-1];

    // Memory to hold test data
    logic signed [DATA_WIDTH-1:0]   ifm_mem    [0:NUM_ROWS-1];
    logic signed [DATA_WIDTH-1:0]   weight_mem [0:NUM_ROWS*NUM_COLS-1];
    logic signed [PE_ACC_WIDTH-1:0] golden_mem [0:NUM_COLS-1];

    PE_Array #(
        .NUM_ROWS(NUM_ROWS),
        .NUM_COLS(NUM_COLS),
        .DATA_WIDTH(DATA_WIDTH),
        .PE_ACC_WIDTH(PE_ACC_WIDTH)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .ifm_in(ifm_in),
        .weight_in(weight_in),
        .psum_out(psum_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    integer i, j, r, c;

    initial begin
        // Initialize inputs
        rst_n = 0;
        for (i = 0; i < NUM_ROWS; i = i + 1) ifm_in[i] = 0;
        
        // Load data
        // Note: Paths must be absolute or relative to simulation execution directory.
        // Adjust these paths if necessary.
        $readmemh("c:/Users/be/Desktop/DNN_Accel/Test_Generator/data/ifm.txt", ifm_mem);
        $readmemh("c:/Users/be/Desktop/DNN_Accel/Test_Generator/data/weights.txt", weight_mem);
        $readmemh("c:/Users/be/Desktop/DNN_Accel/Test_Generator/data/golden.txt", golden_mem);

        // Apply weights (static)
        for (r = 0; r < NUM_ROWS; r = r + 1) begin
            for (c = 0; c < NUM_COLS; c = c + 1) begin
                weight_in[r][c] = weight_mem[r*NUM_COLS + c];
            end
        end

        #20;
        rst_n = 1;
        #10; // Align to clock edge if needed, or just wait a bit.

        // Drive IFM with skew
        // We want to input ifm_mem[r] at cycle r (relative to start)
        
        fork
            // Thread for each row input
            for (i = 0; i < NUM_ROWS; i = i + 1) begin
                fork
                    automatic int row_idx = i;
                    begin
                        // Wait for 'row_idx' cycles
                        repeat (row_idx) @(posedge clk);
                        // Drive input
                        ifm_in[row_idx] <= ifm_mem[row_idx];
                        @(posedge clk);
                        // Clear input (assuming single vector test)
                        ifm_in[row_idx] <= 0;
                    end
                join_none
            end
        join

        // Wait for computation to finish
        // Max latency is NUM_ROWS + NUM_COLS + some margin
        repeat (NUM_ROWS + NUM_COLS + 20) @(posedge clk);
        $display("Simulation Finished.");
        $finish;
    end

    // Monitor and Check
    // Output for col c is valid at cycle: (start_time) + NUM_ROWS + c
    // We started driving at ~30ns.
    // Let's use a counter or just wait for the specific event.
    
    initial begin
        // Wait for reset release
        @(posedge rst_n);
        #10;
        
        // Check each column output at the correct time
        for (j = 0; j < NUM_COLS; j = j + 1) begin
            fork
                automatic int col_idx = j;
                begin
                    // Wait for expected cycle
                    // Latency = NUM_ROWS + col_idx
                    repeat (NUM_ROWS + col_idx) @(posedge clk);
                    
                    // Sample output just before next clock edge or after a small delay
                    #1; 
                    if (psum_out[col_idx] !== golden_mem[col_idx]) begin
                        $display("Error at Col %0d: Expected %h (%0d), Got %h (%0d)", 
                            col_idx, golden_mem[col_idx], $signed(golden_mem[col_idx]), psum_out[col_idx], $signed(psum_out[col_idx]));
                    end else begin
                        $display("Pass at Col %0d: Got %h (%0d)", col_idx, psum_out[col_idx], $signed(psum_out[col_idx]));
                    end
                end
            join_none
        end
    end

endmodule
