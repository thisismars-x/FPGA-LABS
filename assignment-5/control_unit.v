// control_unit.v — Main Control Unit (decodes opcode only)
module control_unit (
    input  wire [6:0] opcode,
    output reg         reg_write,
    output reg         alu_src,
    output reg         mem_write,
    output reg         result_src,   // 0 = ALU result, 1 = memory data
    output reg         branch,
    output reg  [1:0]  imm_src,
    output reg  [1:0]  alu_op
);
    localparam R_TYPE   = 7'b0110011;
    localparam I_TYPE_A = 7'b0010011; // addi, andi, ori...
    localparam LOAD     = 7'b0000011; // lw
    localparam STORE    = 7'b0100011; // sw
    localparam BRANCH   = 7'b1100011; // beq, bne...

    always @(*) begin
        // safe defaults
        reg_write  = 1'b0;
        alu_src    = 1'b0;
        mem_write  = 1'b0;
        result_src = 1'b0;
        branch     = 1'b0;
        imm_src    = 2'b00;
        alu_op     = 2'b00;

        case (opcode)
            R_TYPE: begin
                reg_write = 1'b1;
                alu_src   = 1'b0;
                alu_op    = 2'b10;
            end
            I_TYPE_A: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                imm_src   = 2'b00;
                alu_op    = 2'b10;
            end
            LOAD: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                imm_src    = 2'b00;
                result_src = 1'b1;
                alu_op     = 2'b00;
            end
            STORE: begin
                alu_src   = 1'b1;
                mem_write = 1'b1;
                imm_src   = 2'b01;
                alu_op    = 2'b00;
            end
            BRANCH: begin
                alu_src = 1'b0;
                branch  = 1'b1;
                imm_src = 2'b10;
                alu_op  = 2'b01;
            end
            default: ; // NOP / unsupported opcode -> all defaults (safe)
        endcase
    end
endmodule
