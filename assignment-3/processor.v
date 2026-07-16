`timescale 1ns/1ps

// processor.v
// Top-level tie-together of program counter, program memory, control
// unit, register file and ALU datapath.
// (Functionally identical to the original "cpu" module.)

module processor(
    input clk
    );

    reg  [7:0] pc;
    wire [7:0] pc_next;
    wire       pc_en_w;

    pc_inc u_pc_inc (
        .pc_cur  (pc),
        .pc_next (pc_next)
    );

    initial pc = 8'd0;
    always @(posedge clk) if (pc_en_w) pc <= pc_next;

    wire [7:0] instr;

    progmem u_progmem (
        .addr (pc),
        .data (instr)
    );

    wire [7:0] imm_w;
    wire [2:0] rsel1_w;     // -> straight to ALU operand2
    wire [2:0] rsel2_w;     // -> 2's-comp / imm mux -> ALU operand1
    wire [2:0] wsel_w;
    wire       wen_w;
    wire [2:0] aluop_w;
    wire       negsel_w;
    wire       immsel_w;

    ctrl_unit u_ctrl_unit (
        .clk     (clk),
        .instr   (instr),
        .imm_out (imm_w),
        .rd_sel1 (rsel1_w),
        .rd_sel2 (rsel2_w),
        .wr_sel  (wsel_w),
        .wr_en   (wen_w),
        .alu_sel (aluop_w),
        .neg_sel (negsel_w),
        .imm_sel (immsel_w),
        .pc_en   (pc_en_w)
    );

    wire [7:0] rdata1_w;    // direct  -> ALU operand2
    wire [7:0] rdata2_w;    // muxed   -> ALU operand1
    wire [7:0] alu_res_w;

    regfile_unit u_regfile (
        .clk      (clk),
        .rd_addr1 (rsel1_w),
        .rd_addr2 (rsel2_w),
        .wr_addr  (wsel_w),
        .wr_data  (alu_res_w),
        .wr_en    (wen_w),
        .rd_data1 (rdata1_w),
        .rd_data2 (rdata2_w)
    );

    wire [7:0] neg_out_w;
    wire [7:0] opA_pre_w;   // result of neg_sel mux: rdata2_w or -rdata2_w

    twos_comp u_twos_comp (
        .in_val  (rdata2_w),
        .neg_val (neg_out_w)
    );

    sub_mux u_sub_mux (
        .neg_in   (neg_out_w),
        .plain_in (rdata2_w),
        .sel      (negsel_w),
        .out_val  (opA_pre_w)
    );

    //--------------------------------------------------------------
    // Immediate MUX  (imm_w vs opA_pre_w) -> ALU operand1
    //--------------------------------------------------------------
    wire [7:0] operand1_w;

    opa_mux u_opa_mux (
        .imm_in  (imm_w),
        .reg_in  (opA_pre_w),
        .sel     (immsel_w),
        .opa_out (operand1_w)
    );

    //--------------------------------------------------------------
    // ALU
    //--------------------------------------------------------------
    wire alu_carry_w;

    alu8 u_alu8 (
        .a   (operand1_w),   // operand1
        .b   (rdata1_w),     // operand2 (direct)
        .sel (aluop_w),
        .o   (alu_res_w),
        .c   (alu_carry_w)
    );

endmodule
