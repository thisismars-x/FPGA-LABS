`timescale 1ns/1ps

// processor_tb.v
// Simple clock-driven testbench: runs the processor for 40 clock
// edges, prints PC / instruction / register contents each cycle, and
// dumps a VCD waveform for GTKWave.
// (Functionally identical to the original "tb_cpu" module.)

module processor_tb;

    reg clk = 0;
    always #5 clk = ~clk;

    processor dut (.clk(clk));

    integer i;

    initial begin
        $dumpfile("processor.vcd");
        $dumpvars(0, processor_tb);

        $display("time  pc   inst   ACC(r0) r1  r2  r3  r4  r5");
        for (i = 0; i < 40; i = i + 1) begin
            @(posedge clk);
            #1;
            $display("%0t  %0d   %0h    %0d  %0d  %0d  %0d  %0d  %0d",
                $time, dut.pc, dut.instr,
                dut.u_regfile.regmem[0],
                dut.u_regfile.regmem[1],
                dut.u_regfile.regmem[2],
                dut.u_regfile.regmem[3],
                dut.u_regfile.regmem[4],
                dut.u_regfile.regmem[5]);
        end
        $finish;
    end

endmodule
