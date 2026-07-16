// alu8.v
// 8-bit ALU supporting ADD / AND / OR / XOR / NOT, plus a carry-out
// flag for the ADD case. (Functionally identical to the original
// "eight_bit_alu" module - encoding of `sel` is unchanged.)

module alu8(
    input  [7:0] a,
    input  [7:0] b,
    input  [2:0] sel,
    output reg [7:0] o,
    output reg       c
    );

    always @(*) begin
        c = 1'b0;
        case (sel)
            3'b001 : {c, o} = a + b;   // ADD
            3'b010 : o = a & b;       // AND
            3'b011 : o = a | b;       // OR
            3'b100 : o = a ^ b;       // XOR
            3'b101 : o = ~a;          // NOT
            default: {c, o} = 9'b0;
        endcase
    end

endmodule
