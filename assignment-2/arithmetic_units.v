// =============================================================
// Building blocks for the ALU's arithmetic path:
//   half_adder  -> 1-bit add, no carry-in
//   fulladder   -> 1-bit add, with carry-in (built from 2 half adders)
//   bit4adder   -> 4-bit ripple-carry adder (4 fulladders chained)
//   bit8adder   -> 8-bit ripple-carry adder (2 bit4adders chained)
//   bit8subtractor -> 8-bit subtractor, reuses bit8adder via
//                     two's-complement (a - b = a + ~b + cin)
// =============================================================

module half_adder(input a,b, output c,s);
	assign s = a ^ b;   // sum bit
	assign c = a & b;   // carry-out bit
endmodule   // note: removed stray ';' after endmodule (invalid syntax)

module fulladder(input a,b,cin, output s,cout);
	wire stemp, ctemp1, ctemp2;

	// stage 1: add the two data bits
	half_adder ha1(.s(stemp), .c(ctemp1), .a(a), .b(b));
	// stage 2: add that partial sum to the incoming carry
	half_adder ha2(.s(s), .c(ctemp2), .a(cin), .b(stemp));

	// carry-out is set if either addition stage produced a carry
	or(cout, ctemp1, ctemp2);
endmodule

// 4-bit ripple-carry adder: carry ripples c1 -> c2 -> c3 -> cout
module bit4adder(input [3:0] a,b,
	 input cin,
	 output cout,
	 output [3:0] sum);

	wire c1, c2, c3;

	fulladder fa0(.a(a[0]),.b(b[0]), .cin(cin), .s(sum[0]), .cout(c1));
	fulladder fa1(.a(a[1]),.b(b[1]), .cin(c1), .s(sum[1]), .cout(c2));
	fulladder fa2(.a(a[2]),.b(b[2]), .cin(c2), .s(sum[2]), .cout(c3));
	fulladder fa3(.a(a[3]),.b(b[3]), .cin(c3), .s(sum[3]), .cout(cout));

	endmodule

// 8-bit adder built from two 4-bit adders; the carry-out of the
// low nibble feeds the carry-in of the high nibble.
module bit8adder(input [7:0] a,b,
	 input cin,
	 output cout,
	 output [7:0] sum);

	wire c1;

	bit4adder adder1(.a(a[3:0]), .b(b[3:0]), .cin(cin), .sum(sum[3:0]), .cout(c1));
	bit4adder adder2(.a(a[7:4]), .b(b[7:4]), .cin(c1), .sum(sum[7:4]), .cout(cout));

	endmodule

// 8-bit subtractor: computes a - b as a + (~b) + cin.
// Caller is expected to drive cin = 1 to complete the two's
// complement (see ALU instantiation: bit8subtractor .cin(1'b1)).
module bit8subtractor(
		input [7:0] a,b,
		input cin,
		output cout,
		output [7:0] diff);

	wire [7:0] notB;
	assign notB = ~b;   // one's complement of b
	bit8adder adder(.a(a), .b(notB), .cin(cin), .cout(cout), .sum(diff));
endmodule
