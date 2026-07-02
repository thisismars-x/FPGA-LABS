// =============================================================
// Combinational barrel shifters: shift `in` left/right by an
// amount 0-7, built from 3 conditional shift stages (by 1, 2,
// then 4 bits) instead of a variable-amount shift operator.
// =============================================================

module leftShift (
    input  wire [7:0] in,
    input  wire [2:0] shift, // shift amount, 0-7
    output wire [7:0] out
);
    wire [7:0] stage1, stage2;

    assign stage1 = shift[0] ? {in[6:0], 1'b0}     : in;      // shift by 1 if bit0 set
    assign stage2 = shift[1] ? {stage1[5:0], 2'b00} : stage1; // shift by 2 if bit1 set
    assign out    = shift[2] ? {stage2[3:0], 4'b0000} : stage2; // shift by 4 if bit2 set

endmodule

module rightShift(
    input  wire [7:0] in,
    input  wire [2:0] shift, // shift amount, 0-7
    output wire [7:0] out
);

    wire [7:0] stage1, stage2;

    assign stage1 = shift[0] ? {1'b0, in[7:1]}     : in;      // shift by 1 if bit0 set
    assign stage2 = shift[1] ? {2'b00, stage1[7:2]} : stage1; // shift by 2 if bit1 set
    assign out    = shift[2] ? {4'b0000, stage2[7:4]} : stage2; // shift by 4 if bit2 set

endmodule
