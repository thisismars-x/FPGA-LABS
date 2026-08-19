// alu_control.v — decides the ALU operation from ALUOp + funct fields
module alu_control (
    input  wire [1:0] alu_op,     // from main Control Unit
    input  wire [2:0] funct3,     // instr[14:12]
    input  wire        funct7_5,   // instr[30]
    output reg  [3:0] alu_control
);
    always @(*) begin
        case (alu_op)
            2'b00: alu_control = 4'b0000;              // lw/sw -> add
            2'b01: alu_control = 4'b0001;              // branch -> subtract
            2'b10: begin                                 // R-type / I-type ALU
                case (funct3)
                    3'b000: alu_control = (funct7_5) ? 4'b0001 : 4'b0000; // sub/add
                    3'b111: alu_control = 4'b0010;      // and
                    3'b110: alu_control = 4'b0011;      // or
                    3'b100: alu_control = 4'b0100;      // xor
                    3'b001: alu_control = 4'b0101;      // sll
                    3'b101: alu_control = (funct7_5) ? 4'b0111 : 4'b0110; // sra/srl
                    3'b010: alu_control = 4'b1000;      // slt
                    3'b011: alu_control = 4'b1001;      // sltu
                    default: alu_control = 4'b0000;
                endcase
            end
            default: alu_control = 4'b0000;
        endcase
    end
endmodule
