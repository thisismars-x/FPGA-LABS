// 8-point radix-2 Decimation-in-Time FFT
// Fixed-point complex arithmetic using signed Q15 twiddle constants.

module fft8_dit #(
    parameter integer DATA_WIDTH = 16
)(
    input  wire                           clk,
    input  wire                           rst,
    input  wire                           load,

    // Packed complex input samples:
    // sample n occupies bits n*DATA_WIDTH +: DATA_WIDTH.
    input  wire signed [8*DATA_WIDTH-1:0] x_re,
    input  wire signed [8*DATA_WIDTH-1:0] x_im,

    output reg                            done,

    output reg signed [DATA_WIDTH-1:0] X0_re, X0_im,
    output reg signed [DATA_WIDTH-1:0] X1_re, X1_im,
    output reg signed [DATA_WIDTH-1:0] X2_re, X2_im,
    output reg signed [DATA_WIDTH-1:0] X3_re, X3_im,
    output reg signed [DATA_WIDTH-1:0] X4_re, X4_im,
    output reg signed [DATA_WIDTH-1:0] X5_re, X5_im,
    output reg signed [DATA_WIDTH-1:0] X6_re, X6_im,
    output reg signed [DATA_WIDTH-1:0] X7_re, X7_im
);

    localparam [2:0] S_IDLE   = 3'd0;
    localparam [2:0] S_LOAD   = 3'd1;
    localparam [2:0] S_STAGE1 = 3'd2;
    localparam [2:0] S_STAGE2 = 3'd3;
    localparam [2:0] S_STAGE3 = 3'd4;
    localparam [2:0] S_DONE   = 3'd5;

    // cos(pi/4) and sin(pi/4) represented in Q15.
    localparam signed [15:0] TWIDDLE_45 = 16'sd23170;

    reg [2:0] state;
    reg [3:0] sample_index;

    reg signed [DATA_WIDTH-1:0] input_re [0:7];
    reg signed [DATA_WIDTH-1:0] input_im [0:7];

    reg signed [DATA_WIDTH-1:0] stage1_re [0:7];
    reg signed [DATA_WIDTH-1:0] stage1_im [0:7];

    reg signed [DATA_WIDTH-1:0] stage2_re [0:7];
    reg signed [DATA_WIDTH-1:0] stage2_im [0:7];

    reg signed [DATA_WIDTH-1:0] stage3_re [0:7];
    reg signed [DATA_WIDTH-1:0] stage3_im [0:7];

    // Wider temporaries avoid losing the product before the Q15 shift.
    reg signed [31:0] mult_re;
    reg signed [31:0] mult_im;

    integer i;

    function [2:0] reverse3(input [2:0] value);
        begin
            reverse3 = {value[0], value[1], value[2]};
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state        <= S_IDLE;
            sample_index <= 0;
            done         <= 1'b0;

            X0_re <= 0; X0_im <= 0;
            X1_re <= 0; X1_im <= 0;
            X2_re <= 0; X2_im <= 0;
            X3_re <= 0; X3_im <= 0;
            X4_re <= 0; X4_im <= 0;
            X5_re <= 0; X5_im <= 0;
            X6_re <= 0; X6_im <= 0;
            X7_re <= 0; X7_im <= 0;
        end
        else begin
            case (state)

                S_IDLE: begin
                    done         <= 1'b0;
                    sample_index <= 0;

                    if (load)
                        state <= S_LOAD;
                end

                // Load one sample per clock and place it in bit-reversed order.
                S_LOAD: begin
                    input_re[reverse3(sample_index[2:0])] <=
                        x_re[sample_index[2:0]*DATA_WIDTH +: DATA_WIDTH];

                    input_im[reverse3(sample_index[2:0])] <=
                        x_im[sample_index[2:0]*DATA_WIDTH +: DATA_WIDTH];

                    if (sample_index == 7) begin
                        sample_index <= 0;
                        state <= S_STAGE1;
                    end
                    else begin
                        sample_index <= sample_index + 1'b1;
                    end
                end

                // Butterfly distance = 1.
                S_STAGE1: begin
                    for (i = 0; i < 8; i = i + 2) begin
                        stage1_re[i]   <= input_re[i] + input_re[i+1];
                        stage1_im[i]   <= input_im[i] + input_im[i+1];
                        stage1_re[i+1] <= input_re[i] - input_re[i+1];
                        stage1_im[i+1] <= input_im[i] - input_im[i+1];
                    end

                    state <= S_STAGE2;
                end

                // Butterfly distance = 2.
                // Multiplication by -j is implemented as (b, -a).
                S_STAGE2: begin
                    for (i = 0; i < 8; i = i + 4) begin
                        stage2_re[i]   <= stage1_re[i] + stage1_re[i+2];
                        stage2_im[i]   <= stage1_im[i] + stage1_im[i+2];

                        stage2_re[i+2] <= stage1_re[i] - stage1_re[i+2];
                        stage2_im[i+2] <= stage1_im[i] - stage1_im[i+2];

                        stage2_re[i+1] <= stage1_re[i+1] + stage1_im[i+3];
                        stage2_im[i+1] <= stage1_im[i+1] - stage1_re[i+3];

                        stage2_re[i+3] <= stage1_re[i+1] - stage1_im[i+3];
                        stage2_im[i+3] <= stage1_im[i+1] + stage1_re[i+3];
                    end

                    state <= S_STAGE3;
                end

                // Final radix-2 stage.
                // W8^0 = 1, W8^1 = (1-j)/sqrt(2),
                // W8^2 = -j, W8^3 = (-1-j)/sqrt(2).
                S_STAGE3: begin
                    stage3_re[0] <= stage2_re[0] + stage2_re[4];
                    stage3_im[0] <= stage2_im[0] + stage2_im[4];
                    stage3_re[4] <= stage2_re[0] - stage2_re[4];
                    stage3_im[4] <= stage2_im[0] - stage2_im[4];

                    // W8^1 = (1-j)/sqrt(2)
                    mult_re = $signed(stage2_re[5] + stage2_im[5])
                              * $signed(TWIDDLE_45);
                    mult_im = $signed(stage2_im[5] - stage2_re[5])
                              * $signed(TWIDDLE_45);

                    stage3_re[1] <= stage2_re[1] + (mult_re >>> 15);
                    stage3_im[1] <= stage2_im[1] + (mult_im >>> 15);
                    stage3_re[5] <= stage2_re[1] - (mult_re >>> 15);
                    stage3_im[5] <= stage2_im[1] - (mult_im >>> 15);

                    // W8^2 = -j
                    stage3_re[2] <= stage2_re[2] + stage2_im[6];
                    stage3_im[2] <= stage2_im[2] - stage2_re[6];
                    stage3_re[6] <= stage2_re[2] - stage2_im[6];
                    stage3_im[6] <= stage2_im[2] + stage2_re[6];

                    // W8^3 = (-1-j)/sqrt(2)
                    mult_re = $signed(stage2_im[7] - stage2_re[7])
                              * $signed(TWIDDLE_45);
                    mult_im = $signed(-stage2_re[7] - stage2_im[7])
                              * $signed(TWIDDLE_45);

                    stage3_re[3] <= stage2_re[3] + (mult_re >>> 15);
                    stage3_im[3] <= stage2_im[3] + (mult_im >>> 15);
                    stage3_re[7] <= stage2_re[3] - (mult_re >>> 15);
                    stage3_im[7] <= stage2_im[3] - (mult_im >>> 15);

                    state <= S_DONE;
                end

                S_DONE: begin
                    done <= 1'b1;

                    X0_re <= stage3_re[0]; X0_im <= stage3_im[0];
                    X1_re <= stage3_re[1]; X1_im <= stage3_im[1];
                    X2_re <= stage3_re[2]; X2_im <= stage3_im[2];
                    X3_re <= stage3_re[3]; X3_im <= stage3_im[3];
                    X4_re <= stage3_re[4]; X4_im <= stage3_im[4];
                    X5_re <= stage3_re[5]; X5_im <= stage3_im[5];
                    X6_re <= stage3_re[6]; X6_im <= stage3_im[6];
                    X7_re <= stage3_re[7]; X7_im <= stage3_im[7];

                    // Return to idle after the result has been observed.
                    if (!load)
                        state <= S_IDLE;
                end

                default: begin
                    state <= S_IDLE;
                end

            endcase
        end
    end

endmodule
