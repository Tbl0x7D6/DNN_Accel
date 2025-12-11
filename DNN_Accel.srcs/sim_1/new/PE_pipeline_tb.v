`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/10/2025 12:08:03 AM
// Design Name: 
// Module Name: PE_pipeline_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module PE_pipeline_tb();

    reg clk;
    reg kernel_type;  // 0: 3x3, 1: 5x5
    reg stride;       // 0: 1,   1: 2
    reg use_prev_psum [2:0];  // 0: ignore psum_data, 1: use psum_data

    reg start [2:0];
    reg [7:0] ifm [3:0][35:0];
    reg [7:0] filter [2:0][4:0];

    // simulate another channel (kernel) and ifm
    // make sure PE can handle continuous data input
    reg [7:0] ifm2 [3:0][35:0];
    reg [7:0] filter2 [2:0][4:0];

    // Signals for PE connections
    reg [7:0] pe_ifm_data1 [2:0][35:0];
    reg [7:0] pe_ifm_data2 [2:0][35:0];
    reg [7:0] pe_filter_data [2:0][4:0];
    wire [20:0] pe_psum_data1 [2:0];
    wire [20:0] pe_psum_data2 [2:0];
    wire [20:0] pe_psum_out1 [2:0];
    wire [20:0] pe_psum_out2 [2:0];

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    generate
        for (genvar i = 0; i < 3; i = i + 1) begin : PE_GEN
            PE pe_inst (
                .clk(clk),
                .start(start[i]),
                .kernel_type(kernel_type),
                .stride(stride),
                .use_prev_psum(use_prev_psum[i]),
                .ifm_data1(pe_ifm_data1[i]),
                .ifm_data2(pe_ifm_data2[i]),
                .filter_data(pe_filter_data[i]),
                .psum_data1(pe_psum_data1[i]),
                .psum_data2(pe_psum_data2[i]),
                .psum_out1(pe_psum_out1[i]),
                .psum_out2(pe_psum_out2[i])
            );
        end
    endgenerate

    // init
    initial begin
        start[0] = 0;
        start[1] = 0;
        start[2] = 0;
        kernel_type = 0;
        stride = 0;
        use_prev_psum[0] = 0;
        use_prev_psum[1] = 1;
        use_prev_psum[2] = 1;
        
        // init IFM
        for (integer i = 0; i < 36; i = i + 1) begin
            ifm[0][i] = i % 2 + 1;   // 1, 2, 1, 2, 1, 2, 1, 2, 1, ...
            ifm[1][i] = i + 1;       // 1, 2, 3, 4, 5, 6, 7, 8, 9, ...
            ifm[2][i] = 1;           // 1, 1, 1, 1, 1, 1, 1, 1, 1, ...
            ifm[3][i] = 7 - (i % 7); // 7, 6, 5, 4, 3, 2, 1, 7, 6, ...
        end
        
        // init filter
        for (integer i = 0; i < 3; i = i + 1) begin
            filter[0][i] = i + 1;      // 1, 2, 3
            filter[1][i] = 1;          // 1, 1, 1
            filter[2][i] = 3 - i;      // 3, 2, 1
        end
        filter[0][3] = 0;
        filter[0][4] = 0;
        filter[1][3] = 0;
        filter[1][4] = 0;
        filter[2][3] = 0;
        filter[2][4] = 0;

        // another IFM and filter
        for (integer i = 0; i < 36; i = i + 1) begin
            ifm2[0][i] = i % 2;    // 0, 1, 0, 1, 0, 1, 0, 1, 0, ...
            ifm2[1][i] = i % 3;   // 0, 1, 2, 0, 1, 2, 0, 1, 2, ...
            ifm2[2][i] = i % 4;   // 0, 1, 2, 3, 0, 1, 2, 3, 0, ...
            ifm2[3][i] = i % 5;   // 0, 1, 2, 3, 4, 0, 1, 2, 3, ...
        end

        for (integer i = 0; i < 3; i = i + 1) begin
            filter2[i][0] = 1;
            filter2[i][1] = 0;
            filter2[i][2] = 1;
            filter2[i][3] = 0;
            filter2[i][4] = 0;
        end

        // connect data to PE inputs
        for (integer i = 0; i < 3; i = i + 1) begin
            for (integer j = 0; j < 36; j = j + 1) begin
                pe_ifm_data1[i][j] = ifm[i][j];
                pe_ifm_data2[i][j] = ifm[i+1][j];
            end
            for (integer j = 0; j < 5; j = j + 1) begin
                pe_filter_data[i][j] = filter[i][j];
            end
        end
    end

    // psum pipeline
    assign pe_psum_data1[1] = pe_psum_out1[0];
    assign pe_psum_data2[1] = pe_psum_out2[0];
    assign pe_psum_data1[2] = pe_psum_out1[1];
    assign pe_psum_data2[2] = pe_psum_out2[1];

    // start signal
    // 相邻 PE 单元 start 之间间隔 kernel_size = 3 cycles
    // 正确的输出是在距离第一个 start 4(dsp)+3*3 = 13 cycles 后
    // 在 pe_psum_out1/2[2] 观察到两个 ofm 行的输出，每隔 3 cycles 移动一列
    // ofm1: 20 25 26 31 32 37 38 43 44 49 50 55 ...
    // ofm2: 55 55 55 55 55 62 76 97 97 97 97 97 ...
    initial begin
        #20;
        @(posedge clk);
        start[0] = 1;
        @(posedge clk);
        start[0] = 0;
        @(posedge clk);

        @(posedge clk);
        start[1] = 1;
        @(posedge clk);
        start[1] = 0;
        @(posedge clk);

        @(posedge clk);
        start[2] = 1;
        @(posedge clk);
        start[2] = 0;
    end

    // 测试第二组数据输入
    // 假设第一组 ofm 有 12 列，那么应该再等 12*3 = 36 cycles 后输入 start
    // 必须精确地在 start 高电平那一个周期把所有数据换掉
    // 然后在 13 cycles 后观察到输出
    // ofm1: 4 7 5  8 3 9 4 7  5 8  3 9
    // ofm2: 6 9 11 9 8 9 8 11 8 11 5 11
    initial begin
        #20;
        repeat(36) @(posedge clk);

        @(posedge clk);
        start[0] = 1;

        for (integer j = 0; j < 36; j = j + 1) begin
            pe_ifm_data1[0][j] = ifm2[0][j];
            pe_ifm_data2[0][j] = ifm2[1][j];
        end
        for (integer j = 0; j < 5; j = j + 1) begin
            pe_filter_data[0][j] = filter2[0][j];
        end

        @(posedge clk);
        start[0] = 0;
        @(posedge clk);

        @(posedge clk);
        start[1] = 1;

        for (integer j = 0; j < 36; j = j + 1) begin
            pe_ifm_data1[1][j] = ifm2[1][j];
            pe_ifm_data2[1][j] = ifm2[2][j];
        end
        for (integer j = 0; j < 5; j = j + 1) begin
            pe_filter_data[1][j] = filter2[1][j];
        end

        @(posedge clk);
        start[1] = 0;
        @(posedge clk);

        @(posedge clk);
        start[2] = 1;

        for (integer j = 0; j < 36; j = j + 1) begin
            pe_ifm_data1[2][j] = ifm2[2][j];
            pe_ifm_data2[2][j] = ifm2[3][j];
        end
        for (integer j = 0; j < 5; j = j + 1) begin
            pe_filter_data[2][j] = filter2[2][j];
        end
        @(posedge clk);

        start[2] = 0;

        #500;
        $finish;
    end

endmodule
