// alu.v — Arithmetic Logic Unit
module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_control,
    output reg  [31:0] result,
    output wire         zero
);
    // ALU control encoding:
    // 0000 = ADD   0001 = SUB   0010 = AND   0011 = OR
    // 0100 = XOR   0101 = SLL   0110 = SRL   0111 = SRA
    // 1000 = SLT   1001 = SLTU

    always @(*) begin
        case (alu_control)
            4'b0000: result = a + b;
            4'b0001: result = a - b;
            4'b0010: result = a & b;
            4'b0011: result = a | b;
            4'b0100: result = a ^ b;
            4'b0101: result = a << b[4:0];
            4'b0110: result = a >> b[4:0];
            4'b0111: result = $signed(a) >>> b[4:0];
            4'b1000: result = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0;
            4'b1001: result = (a < b) ? 32'b1 : 32'b0;
            default: result = 32'b0;
        endcase
    end

    assign zero = (result == 32'b0);
endmodule
