// subsel.v
// Chooses between the negated operand (for subtraction) and the
// plain operand (for addition/pass-through).
// (Functionally identical to the original "compmux" module.)

module sub_mux(
    input  [7:0] neg_in,
    input  [7:0] plain_in,
    input        sel,
    output reg [7:0] out_val
    );

    always @(*) begin
        if (sel)
            out_val = neg_in;
        else
            out_val = plain_in;
    end

endmodule
