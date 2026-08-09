`timescale 1ns/1ps

module tb_fft8_dit;

    localparam integer DATA_WIDTH = 16;

    reg clk;
    reg rst;
    reg load;

    reg signed [8*DATA_WIDTH-1:0] x_re;
    reg signed [8*DATA_WIDTH-1:0] x_im;

    wire done;

    wire signed [DATA_WIDTH-1:0] X0_re, X0_im;
    wire signed [DATA_WIDTH-1:0] X1_re, X1_im;
    wire signed [DATA_WIDTH-1:0] X2_re, X2_im;
    wire signed [DATA_WIDTH-1:0] X3_re, X3_im;
    wire signed [DATA_WIDTH-1:0] X4_re, X4_im;
    wire signed [DATA_WIDTH-1:0] X5_re, X5_im;
    wire signed [DATA_WIDTH-1:0] X6_re, X6_im;
    wire signed [DATA_WIDTH-1:0] X7_re, X7_im;

    fft8_dit #(.DATA_WIDTH(DATA_WIDTH)) dut (
        .clk(clk),
        .rst(rst),
        .load(load),
        .x_re(x_re),
        .x_im(x_im),
        .done(done),

        .X0_re(X0_re), .X0_im(X0_im),
        .X1_re(X1_re), .X1_im(X1_im),
        .X2_re(X2_re), .X2_im(X2_im),
        .X3_re(X3_re), .X3_im(X3_im),
        .X4_re(X4_re), .X4_im(X4_im),
        .X5_re(X5_re), .X5_im(X5_im),
        .X6_re(X6_re), .X6_im(X6_im),
        .X7_re(X7_re), .X7_im(X7_im)
    );

    // 10 ns clock period.
    always #5 clk = ~clk;

    initial begin
        $dumpfile("fft8_sim.vcd");
        $dumpvars(0, tb_fft8_dit);

        clk  = 1'b0;
        rst  = 1'b1;
        load = 1'b0;
        x_re = '0;
        x_im = '0;

        // Reset the design.
        #20;
        rst = 1'b0;

        // x[n] = 100(n+1) + j*100(8-n)
        x_re[0*DATA_WIDTH +: DATA_WIDTH] = 16'sd100;
        x_im[0*DATA_WIDTH +: DATA_WIDTH] = 16'sd800;

        x_re[1*DATA_WIDTH +: DATA_WIDTH] = 16'sd200;
        x_im[1*DATA_WIDTH +: DATA_WIDTH] = 16'sd700;

        x_re[2*DATA_WIDTH +: DATA_WIDTH] = 16'sd300;
        x_im[2*DATA_WIDTH +: DATA_WIDTH] = 16'sd600;

        x_re[3*DATA_WIDTH +: DATA_WIDTH] = 16'sd400;
        x_im[3*DATA_WIDTH +: DATA_WIDTH] = 16'sd500;

        x_re[4*DATA_WIDTH +: DATA_WIDTH] = 16'sd500;
        x_im[4*DATA_WIDTH +: DATA_WIDTH] = 16'sd400;

        x_re[5*DATA_WIDTH +: DATA_WIDTH] = 16'sd600;
        x_im[5*DATA_WIDTH +: DATA_WIDTH] = 16'sd300;

        x_re[6*DATA_WIDTH +: DATA_WIDTH] = 16'sd700;
        x_im[6*DATA_WIDTH +: DATA_WIDTH] = 16'sd200;

        x_re[7*DATA_WIDTH +: DATA_WIDTH] = 16'sd800;
        x_im[7*DATA_WIDTH +: DATA_WIDTH] = 16'sd100;

        // Keep load asserted for one clock so all eight samples are captured.
        #10;
        load = 1'b1;
        #10;
        load = 1'b0;

        // The FFT takes the load cycle plus three processing stages.
        @(posedge done);
        #1;

        $display("");
        $display("==============================================");
        $display("          8-POINT DIT FFT RESULTS");
        $display("==============================================");
        $display("Input: x[n] = 100(n+1) + j*100(8-n)");
        $display("----------------------------------------------");
        $display("X[0] = %6d + j(%6d)", X0_re, X0_im);
        $display("X[1] = %6d + j(%6d)", X1_re, X1_im);
        $display("X[2] = %6d + j(%6d)", X2_re, X2_im);
        $display("X[3] = %6d + j(%6d)", X3_re, X3_im);
        $display("X[4] = %6d + j(%6d)", X4_re, X4_im);
        $display("X[5] = %6d + j(%6d)", X5_re, X5_im);
        $display("X[6] = %6d + j(%6d)", X6_re, X6_im);
        $display("X[7] = %6d + j(%6d)", X7_re, X7_im);
        $display("----------------------------------------------");
        $display("FFT completed successfully.");
        $display("==============================================");
        $display("");

        #20;
        $finish;
    end

endmodule
