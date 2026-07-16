// opamux.v
// Selects whether ALU operand-1 comes from the immediate byte or
// from the (possibly negated) register value.
// (Functionally identical to the original "immux" module.)

module opa_mux(
    input  [7:0] imm_in,
    input  [7:0] reg_in,
    input        sel,
    output reg [7:0] opa_out
    );

    always @(*) begin
        if (sel)
            opa_out = imm_in;
        else
            opa_out = reg_in;
    end

endmodule
