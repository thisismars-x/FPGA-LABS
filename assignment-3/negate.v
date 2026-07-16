// negate.v
// Produces the two's-complement negation of an 8-bit input.
// (Functionally identical to the original "compi" module.)

module twos_comp(
    input  [7:0] in_val,
    output reg [7:0] neg_val
    );

    always @(*) begin
        neg_val = ~in_val + 1'b1;
    end

endmodule
