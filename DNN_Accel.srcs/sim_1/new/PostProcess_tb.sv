`timescale 1ns / 1ps

module PostProcess_tb;

    Conv_tb uut();

    logic rst_n;
    logic done;

    logic [7:0] Q = 9;

    PostProcess postprocess_inst (
        .clk(uut.clk),
        .rst_n(rst_n),
        .out_size(uut.out_size),
        .ofm_channels(uut.ofm_channels),
        .Q(Q),

        .input_rd_data(uut.ofm_rd_data),
        .input_rd_addr(uut.ofm_rd_addr),

        .input_wr_addr(uut.ofm_wr_addr),
        .input_wr_en(uut.ofm_wr_en),

        .output_data(uut.ifm_wr_data),
        .output_addr(uut.ifm_addr),
        .output_en(uut.ifm_wr_en),

        .done(done)
    );

    logic signed [7:0] golden_mem [0:2048*16-1];

    integer i, j, k, l, m;
    integer idx;

    initial begin
        rst_n = 0;
        wait(uut.done);
        #100;
        uut.conv_rst_n = 0;
        uut.ofm_wr_data = 0;
        #100;

        $readmemh("c:/Users/be/Desktop/DNN_Accel/Test_Generator/data/golden_activated.txt", golden_mem);
        $fscanf(uut.fp, "%d\n", Q);
        rst_n = 1;

        wait(done);
        #100;
        $display("Simulation Finished.");

        for (i = 0; i < uut.out_size; i = i + 1) begin
            for (j = 0; j < uut.out_size; j = j + 1) begin
                for (k = 0; k < uut.ofm_channels / 16; k = k + 1) begin
                    logic signed [127:0] dut_output;
                    idx = (i * uut.out_size + j) * (uut.ofm_channels / 16) + k;
                    dut_output = uut.ifm_bram_inst.xpm_memory_base_inst.mem[idx];
                    for (l = 0; l < 16; l = l + 1) begin
                        logic signed [7:0] dut_val;
                        dut_val = $signed(dut_output[l*8 +: 8]);
                        $display("Checking OFM(%0d,%0d,%0d): DUT=%0d, GOLDEN=%0d",
                                 i, j, k * 16 + l, dut_val, golden_mem[idx * 16 + l]);
                        if (dut_val !== golden_mem[idx * 16 + l]) begin
                            $display("Mismatch at OFM(%0d,%0d,%0d): DUT=%0d, GOLDEN=%0d",
                                    i, j, k * 16 + l, dut_val, golden_mem[idx * 16 + l]);
                        end
                    end
                end
            end
        end

        // check if correctly reset ofm bram to 0
        for (i = 0; i < uut.out_size; i = i + 1) begin
            for (j = 0; j < uut.out_size; j = j + 1) begin
                for (k = 0; k < uut.ofm_channels / 16; k = k + 1) begin
                    logic signed [127:0] dut_output;
                    idx = (i * uut.out_size + j) * (uut.ofm_channels / 16) + k;
                    dut_output = uut.output_bram_inst.xpm_memory_base_inst.mem[idx];
                    for (l = 0; l < 16; l = l + 1) begin
                        logic signed [7:0] dut_val;
                        dut_val = $signed(dut_output[l*8 +: 8]);
                        if (dut_val !== 0) begin
                            $display("Reset Mismatch at (%0d,%0d,%0d): DUT=%0d, GOLDEN=0",
                                    i, j, k * 16 + l, dut_val);
                            $finish;
                        end
                    end
                end
            end
        end

        $finish;
    end

endmodule
