// mux2.v — generic WIDTH-bit 2-to-1 mux
module mux2 #(parameter WIDTH = 32) (
    input  wire             sel,
    input  wire [WIDTH-1:0] d0,
    input  wire [WIDTH-1:0] d1,
    output wire [WIDTH-1:0] y
);
    assign y = sel ? d1 : d0;
endmodule
