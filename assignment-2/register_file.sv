// =============================================================
// A small bank of general-purpose registers sharing one
// bidirectional data bus. register[0] doubles as the accumulator
// (exposed separately as acc_out).
//
// Write source is chosen by alu_db_bar:
//   alu_db_bar = 1 -> write comes from the ALU (alu_input)
//   alu_db_bar = 0 -> write comes from the shared data_bus
//
// swp triggers a same-cycle swap of register[reg_sel[0]] and
// register[reg_sel[1]] instead of a normal read/write.
// =============================================================
module register_bank #(
    parameter int NO_REGISTERS = 8,
    parameter int DATA_LINES   = 8
) (
    input logic clk,
    inout wire [DATA_LINES - 1:0] data_bus,
    input alu_db_bar,
    input rd_wr_bar,
    input swp,
    input logic [2:0] reg_sel[1:0],
    input logic cs,
    input [DATA_LINES - 1:0] alu_input,
    output logic [DATA_LINES - 1 : 0] alu_out[1:0],
    output wire [DATA_LINES - 1:0] acc_out
);
  reg [DATA_LINES - 1:0] register[0:NO_REGISTERS - 1];

  // Drive data_bus with the selected register's value only when
  // reading (rd_wr_bar=1) and the source isn't the ALU; otherwise
  // release the bus to high-Z.
  assign data_bus = (cs && rd_wr_bar && !alu_db_bar) ? register[reg_sel[0]] : 'z;

  // Both selected registers are always exposed to the ALU as
  // its two operands, regardless of cs/rd_wr_bar.
  assign alu_out[0] = register[reg_sel[0]];
  assign alu_out[1] = register[reg_sel[1]];
  assign acc_out = register[0];

  logic [DATA_LINES-1:0] temp;
  always_ff @(posedge clk) begin : blockName
    if (cs) begin
      if (swp) begin
        // exchange the two selected registers
        temp = register[reg_sel[0]];
        register[reg_sel[0]] <= register[reg_sel[1]];
        register[reg_sel[1]] <= temp;
      end else if (!rd_wr_bar) begin
        // normal write: pick the source based on alu_db_bar
        if (alu_db_bar) begin
          register[reg_sel[0]] <= alu_input;
        end else begin
          register[reg_sel[0]] <= data_bus;
        end
      end
    end
  end

endmodule
