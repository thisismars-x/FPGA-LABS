// ctrl_unit.v
// Instruction decoder / finite-state-machine controller.
// Drives the register file, ALU operand muxes and the ALU op-select
// signal from the current 8-bit instruction byte.
// (Functionally identical to the original "control" module - the
// instruction encoding and timing are unchanged.)

module ctrl_unit(
    input        clk,
    input  [7:0] instr,
    output reg [7:0] imm_out,
    output reg [2:0] rd_sel1,     // -> straight to ALU operand2
    output reg [2:0] rd_sel2,     // -> through 2's-comp/imm mux -> ALU operand1
    output reg [2:0] wr_sel,
    output reg       wr_en,
    output reg [2:0] alu_sel,
    output reg       neg_sel,     // 2's-complement mux control (subtract)
    output reg       imm_sel,     // immediate mux control
    output reg       pc_en
    );

    localparam [2:0] ACC_ADDR = 3'b000;   // accumulator register address
    localparam [2:0] G_ADDR   = 3'b110;   // hard-wired constant = 8'd1
    localparam [2:0] H_ADDR   = 3'b111;   // hard-wired constant = 8'd0

    // ALU sel encoding as implemented in alu8.v (must match alu8.v)
    localparam [2:0] ALU_ADD  = 3'b001;
    localparam [2:0] ALU_AND  = 3'b010;
    localparam [2:0] ALU_OR   = 3'b011;
    localparam [2:0] ALU_XOR  = 3'b100;
    localparam [2:0] ALU_NOT  = 3'b101;

    localparam [1:0] ST_DECODE = 2'b00;
    localparam [1:0] ST_FETCH  = 2'b01;
    localparam [1:0] ST_EXEC   = 2'b10;

    reg [1:0] state;

    always @(*) begin
        wr_en = (state == ST_EXEC);
        pc_en = (state != ST_EXEC);   // hold PC during writeback cycle
    end

    initial begin
        state   = ST_DECODE;
        imm_out = 8'd0;
        rd_sel1 = 3'd0;
        rd_sel2 = 3'd0;
        wr_sel  = 3'd0;
        alu_sel = 3'd0;
        neg_sel = 1'b0;
        imm_sel = 1'b0;
    end

    always @(posedge clk) begin
        case (state)

            ST_DECODE: begin
                neg_sel <= 1'b0;

                case (instr[7:6])

                    2'b00: begin // mov reg <- reg
                        rd_sel2 <= instr[2:0];   // source -> operand2 path (imm_sel=0, neg_sel=0)
                        rd_sel1 <= H_ADDR;       // constant 0
                        wr_sel  <= instr[5:3];   // destination
                        alu_sel <= ALU_ADD;      // a+0 = pass-through
                        imm_sel <= 1'b0;
                        state   <= ST_EXEC;
                    end

                    2'b01: begin // mov reg <- immediate
                        wr_sel  <= instr[5:3];
                        rd_sel1 <= H_ADDR;       // constant 0
                        rd_sel2 <= H_ADDR;       // don't-care, overridden by imm_sel
                        alu_sel <= ALU_ADD;      // imm+0 = pass-through
                        imm_sel <= 1'b1;
                        state   <= ST_FETCH;     // next byte is data, not an opcode
                    end

                    2'b10: begin
                        wr_sel  <= ACC_ADDR;     // ALU result always -> accumulator
                        imm_sel <= 1'b0;

                        case (instr[2:0])
                            3'b001: begin // ADD : ACC + R
                                rd_sel2 <= ACC_ADDR;
                                rd_sel1 <= instr[5:3];
                                alu_sel <= ALU_ADD;
                                neg_sel <= 1'b0;
                            end
                            3'b010: begin // INC : ACC + 1
                                rd_sel2 <= ACC_ADDR;
                                rd_sel1 <= G_ADDR;
                                alu_sel <= ALU_ADD;
                                neg_sel <= 1'b0;
                            end
                            3'b011: begin // DEC : ACC - 1, via 2's complement
                                rd_sel1 <= ACC_ADDR;
                                rd_sel2 <= G_ADDR;   // negated by neg_sel -> -1
                                alu_sel <= ALU_ADD;
                                neg_sel <= 1'b1;
                            end
                            3'b100: begin // XOR : ACC ^ R
                                rd_sel2 <= ACC_ADDR;
                                rd_sel1 <= instr[5:3];
                                alu_sel <= ALU_XOR;
                                neg_sel <= 1'b0;
                            end
                            3'b101: begin // AND : ACC & R
                                rd_sel2 <= ACC_ADDR;
                                rd_sel1 <= instr[5:3];
                                alu_sel <= ALU_AND;
                                neg_sel <= 1'b0;
                            end
                            3'b110: begin // OR : ACC | R
                                rd_sel2 <= ACC_ADDR;
                                rd_sel1 <= instr[5:3];
                                alu_sel <= ALU_OR;
                                neg_sel <= 1'b0;
                            end
                            3'b111: begin // NOT : ~ACC (unary)
                                rd_sel2 <= ACC_ADDR;
                                rd_sel1 <= H_ADDR;
                                alu_sel <= ALU_NOT;
                                neg_sel <= 1'b0;
                            end
                            default: begin
                                rd_sel2 <= ACC_ADDR;
                                rd_sel1 <= instr[5:3];
                                alu_sel <= ALU_ADD;
                                neg_sel <= 1'b0;
                            end
                        endcase

                        state <= ST_EXEC;
                    end

                    default: state <= ST_DECODE;

                endcase
            end

            ST_FETCH: begin
                imm_out <= instr;
                state   <= ST_EXEC;
            end

            ST_EXEC: begin
                state <= ST_DECODE;
            end

            default: state <= ST_DECODE;
        endcase
    end

endmodule
