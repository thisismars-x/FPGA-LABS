// imm_gen.v — Immediate Generator / Sign-Extend unit
module imm_gen (
    input  wire [31:0] instr,
    input  wire [1:0]  imm_src,   // 00 = I-type, 01 = S-type, 10 = B-type
    output reg  [31:0] imm_ext
);
    always @(*) begin
        case (imm_src)
            2'b00: // I-type (addi, lw, jalr): imm[11:0] = instr[31:20]
                imm_ext = {{20{instr[31]}}, instr[31:20]};

            2'b01: // S-type (sw): imm[11:5]=instr[31:25], imm[4:0]=instr[11:7]
                imm_ext = {{20{instr[31]}}, instr[31:25], instr[11:7]};

            2'b10: // B-type (beq/bne/...): imm[12|11|10:5|4:1|0], LSB=0
                imm_ext = {{19{instr[31]}}, instr[31], instr[7],
                           instr[30:25], instr[11:8], 1'b0};

            default:
                imm_ext = 32'b0;
        endcase
    end
endmodule
