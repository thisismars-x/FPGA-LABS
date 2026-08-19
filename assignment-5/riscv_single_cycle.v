// riscv_single_cycle.v — TOP LEVEL: wires every block per the datapath diagram
module riscv_single_cycle (
    input wire clk,
    input wire rst
);

    // ---- PC / fetch ----
    wire [31:0] pc, pc_next, pc_plus4, pc_branch;
    wire [31:0] instr;

    pc_reg u_pc (.clk(clk), .rst(rst), .pc_next(pc_next), .pc(pc));

    adder u_pc_plus4 (.a(pc), .b(32'd4), .sum(pc_plus4));

    instr_mem u_imem (.addr(pc), .instr(instr));

    // ---- Decode fields ----
    wire [6:0] opcode  = instr[6:0];
    wire [4:0] rd_addr = instr[11:7];
    wire [2:0] funct3  = instr[14:12];
    wire [4:0] rs1     = instr[19:15];
    wire [4:0] rs2     = instr[24:20];
    wire       funct7_5 = instr[30];

    // ---- Control signals ----
    wire reg_write, alu_src, mem_write, result_src, branch;
    wire [1:0] imm_src, alu_op;

    control_unit u_ctrl (
        .opcode(opcode), .reg_write(reg_write), .alu_src(alu_src),
        .mem_write(mem_write), .result_src(result_src), .branch(branch),
        .imm_src(imm_src), .alu_op(alu_op)
    );

    wire [3:0] alu_control_sig;
    alu_control u_alu_ctrl (
        .alu_op(alu_op), .funct3(funct3), .funct7_5(funct7_5),
        .alu_control(alu_control_sig)
    );

    // ---- Register file ----
    wire [31:0] reg_rd1, reg_rd2, write_back_data;

    reg_file u_rf (
        .clk(clk), .we3(reg_write),
        .a1(rs1), .a2(rs2), .a3(rd_addr),
        .wd3(write_back_data),
        .rd1(reg_rd1), .rd2(reg_rd2)
    );

    // ---- Immediate generator ----
    wire [31:0] imm_ext;
    imm_gen u_immgen (.instr(instr), .imm_src(imm_src), .imm_ext(imm_ext));

    // ---- ALU operand B mux (ALUSrc) ----
    wire [31:0] alu_b;
    mux2 #(32) u_alu_src_mux (.sel(alu_src), .d0(reg_rd2), .d1(imm_ext), .y(alu_b));

    // ---- ALU ----
    wire [31:0] alu_result;
    wire        alu_zero;
    alu u_alu (
        .a(reg_rd1), .b(alu_b), .alu_control(alu_control_sig),
        .result(alu_result), .zero(alu_zero)
    );

    // ---- Data memory ----
    wire [31:0] mem_read_data;
    data_mem u_dmem (
        .clk(clk), .mem_write(mem_write),
        .addr(alu_result), .write_data(reg_rd2),
        .read_data(mem_read_data)
    );

    // ---- Write-back mux (ResultSrc / MemtoReg) ----
    mux2 #(32) u_wb_mux (
        .sel(result_src), .d0(alu_result), .d1(mem_read_data),
        .y(write_back_data)
    );

    // ---- Branch target & PC mux (PCSrc) ----
    adder u_pc_branch (.a(pc), .b(imm_ext), .sum(pc_branch));

    wire pc_src = branch & alu_zero;
    mux2 #(32) u_pc_mux (.sel(pc_src), .d0(pc_plus4), .d1(pc_branch), .y(pc_next));

endmodule
