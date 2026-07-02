// =============================================================
// Byte-addressable RAM with a bidirectional (tri-state) data
// bus, gated by chip-select (cs) and rd_wr_bar (1 = read, 0 = write).
// When not selected/read, data_bus is driven to high-Z ('z) so
// other devices on the same bus (e.g. the register bank) can drive it.
// =============================================================
module memory #(
    parameter int AD_LINES   = 16,
    parameter int DATA_LINES = 8
) (
    input logic rd_wr_bar,
    input logic [AD_LINES - 1 : 0] addr_bus,
    inout wire [DATA_LINES - 1 : 0] data_bus,
    input logic clk,
    input logic cs
);

  logic [DATA_LINES - 1:0] mem[0:(1<<AD_LINES) -1];

  // Drive the bus only when selected for a read; otherwise release it.
  assign data_bus = (cs && rd_wr_bar) ? mem[addr_bus] : 'z;

  // Synchronous write: on a clock edge, if selected and rd_wr_bar
  // indicates "write" (0), latch whatever is currently on the bus.
  always_ff @(posedge clk) begin
    if (cs && !rd_wr_bar) begin
      mem[addr_bus] <= data_bus;
    end
  end
endmodule
