// pcinc.v
// Combinational "PC + 1" adder used to compute the next program-counter
// value. (Functionally identical to the original "pc_adder" module.)

module pc_inc(
    input  [7:0] pc_cur,
    output [7:0] pc_next
    );

    assign pc_next = pc_cur + 8'd1;

endmodule
