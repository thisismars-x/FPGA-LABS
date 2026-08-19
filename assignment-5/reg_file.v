// reg_file.v — 32 x 32-bit Register File, x0 hardwired to 0
module reg_file (
    input  wire        clk,
    input  wire        we3,        // RegWrite
    input  wire [4:0]  a1,         // rs1
    input  wire [4:0]  a2,         // rs2
    input  wire [4:0]  a3,         // rd  (write address)
    input  wire [31:0] wd3,        // write data
    output wire [31:0] rd1,        // read data 1
    output wire [31:0] rd2         // read data 2
);
    reg [31:0] regs [0:31];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'b0;
    end

    // Synchronous write, x0 never written
    always @(posedge clk) begin
        if (we3 && a3 != 5'b0)
            regs[a3] <= wd3;
    end

    // Combinational read, x0 always reads 0
    assign rd1 = (a1 == 5'b0) ? 32'b0 : regs[a1];
    assign rd2 = (a2 == 5'b0) ? 32'b0 : regs[a2];
endmodule
