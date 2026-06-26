`timescale 1ns/1ps

module alu8_tb;

    reg  [7:0] A, B;
    reg  [3:0] sel;
    wire [7:0] Result;
    wire Cout, Zero, Overflow;

    alu8 uut (
        .A(A),
        .B(B),
        .sel(sel),
        .Result(Result),
        .Cout(Cout),
        .Zero(Zero),
        .Overflow(Overflow)
    );

    // Execute one test
    task test;
        input [63:0] name;
        input [7:0] a, b;
        input [3:0] op;
        begin
            A   = a;
            B   = b;
            sel = op;
            #10;

        $display("%-8s A=%3d(0x%02h) B=%3d(0x%02h) sel=%b -> R=%3d(0x%02h) C=%b Z=%b V=%b",
             name,
             A, A,
             B, B,
             sel,
             Result, Result,
             Cout,
             Zero,
             Overflow);

       end
    endtask

    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, alu8_tb);

        $display("\n============= ALU TEST =============");

        // Basic operations
        test("ADD", 45, 15, 4'b0000);
        test("SUB", 45, 15, 4'b0001);
        test("AND", 45, 15, 4'b0010);
        test("OR",  45, 15, 4'b0011);
        test("XOR", 45, 15, 4'b0100);
        test("NOR", 45, 15, 4'b0101);
        test("NAND",45, 15, 4'b0110);
        test("XNOR",45, 15, 4'b0111);
        test("NOT", 45, 15, 4'b1000);
        test("SLL", 45, 15, 4'b1001);
        test("SRL", 45, 15, 4'b1010);
        test("ROL", 45, 15, 4'b1011);
        test("ROR", 45, 15, 4'b1100);
        test("MUL", 45, 15, 4'b1101);
        test("GT",  45, 15, 4'b1110);
        test("EQ",  45, 15, 4'b1111);

        $display("------------------------------------");

        // Edge cases
        test("ADD_C",   8'hFF, 8'h01, 4'b0000);
        test("SUB_B",   8'd10, 8'd20, 4'b0001);
        test("ZERO",    8'd0,  8'd0,  4'b0011);
        test("ADD_OV",  8'd127,8'd1,  4'b0000);
        test("SUB_OV",  8'h80, 8'h01, 4'b0001);
        test("EQ_T",    8'd99, 8'd99, 4'b1111);

        $display("====================================\n");

        $finish;
    end

endmodule
