// riscv_tb.v — Simple testbench for the single-cycle RV32I core
`timescale 1ns/1ps
module riscv_tb;
    reg clk = 0;
    reg rst = 1;

    riscv_single_cycle dut (.clk(clk), .rst(rst));

    // 100MHz-equivalent clock for simulation
    always #5 clk = ~clk;

    initial begin
        // Dump signals for GTKWave
        $dumpfile("wave.vcd");
        $dumpvars(0, riscv_tb);

        // Preload a tiny test program directly into instruction memory.
        // Example program (machine code, RV32I):
        //   addi x1, x0, 5      -> 0x00500093
        //   addi x2, x0, 10     -> 0x00A00113
        //   add  x3, x1, x2     -> 0x002081B3
        //   sw   x3, 0(x0)      -> 0x00302023
        //   lw   x4, 0(x0)      -> 0x00002203
        dut.u_imem.mem[0] = 32'h00500093;
        dut.u_imem.mem[1] = 32'h00A00113;
        dut.u_imem.mem[2] = 32'h002081B3;
        dut.u_imem.mem[3] = 32'h00302023;
        dut.u_imem.mem[4] = 32'h00002203;

        #10 rst = 0;

        #100;
        $display("x1 = %0d", dut.u_rf.regs[1]);
        $display("x2 = %0d", dut.u_rf.regs[2]);
        $display("x3 = %0d", dut.u_rf.regs[3]);
        $display("x4 = %0d", dut.u_rf.regs[4]);
        $display("mem[0] = %0d", dut.u_dmem.mem[0]);

        $finish;
    end
endmodule
