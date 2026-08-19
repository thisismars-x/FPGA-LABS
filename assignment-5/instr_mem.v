// instr_mem.v — Instruction Memory (read-only, word-addressed via byte PC)
module instr_mem (
    input  wire [31:0] addr,      // byte address (PC)
    output wire [31:0] instr
);
    // 256 words = 1KB of instruction memory
    reg [31:0] mem [0:255];

    initial begin
        // Load a hex program here, e.g.:
        // $readmemh("program.hex", mem);
        // For simulation you can also preload manually in the testbench.
    end

    // word-align: ignore lower 2 bits of byte address
    assign instr = mem[addr[9:2]];
endmodule
