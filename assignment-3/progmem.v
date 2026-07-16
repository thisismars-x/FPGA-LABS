// progmem.v
// Instruction memory pre-loaded with a small demo program that
// exercises MOV(reg<-reg), MOV(reg<-imm), ADD, INC, DEC, XOR, AND,
// OR and NOT. (Functionally identical to the original "imem" module.)

module progmem(
    input  [7:0] addr,
    output reg [7:0] data
    );

    reg [7:0] rom [0:255];
    integer idx;

    initial begin
        rom[8'h00] = 8'h40; // mov ACC(r0) <- imm
        rom[8'h01] = 8'h0A; //   imm = 10            -> ACC = 10
        rom[8'h02] = 8'h48; // mov r1 <- imm
        rom[8'h03] = 8'h05; //   imm = 5             -> r1 = 5
        rom[8'h04] = 8'h11; // mov r2 <- r1 (reg<-reg demo) -> r2 = 5
        rom[8'h05] = 8'h89; // ADD  ACC + r1  = 10 + 5      -> ACC = 15
        rom[8'h06] = 8'h92; // INC  ACC + 1   = 15 + 1      -> ACC = 16
        rom[8'h07] = 8'h9B; // DEC  ACC - 1   = 16 - 1      -> ACC = 15
        rom[8'h08] = 8'h58; // mov r3 <- imm
        rom[8'h09] = 8'hF0; //   imm = 0xF0 (240)   -> r3 = 240
        rom[8'h0A] = 8'h9C; // XOR  ACC ^ r3  = 15 ^ 240    -> ACC = 255
        rom[8'h0B] = 8'h60; // mov r4 <- imm
        rom[8'h0C] = 8'h0F; //   imm = 0x0F (15)    -> r4 = 15
        rom[8'h0D] = 8'hA5; // AND  ACC & r4 = 255 & 15    -> ACC = 15
        rom[8'h0E] = 8'h68; // mov r5 <- imm
        rom[8'h0F] = 8'hAA; //   imm = 0xAA (170)   -> r5 = 170
        rom[8'h10] = 8'hAE; // OR   ACC | r5  = 15 | 170    -> ACC = 175
        rom[8'h11] = 8'hBF; // NOT  ~ACC      = ~175        -> ACC = 80
        for (idx = 18; idx < 256; idx = idx + 1)
            rom[idx] = 8'h00; // NOP (mov r0<-r0) padding
    end

    always @(*) begin
        data = rom[addr];
    end

endmodule
