// =============================================================
// Testbench for data_memory.sv: writes 4 known values to
// different addresses, reads them back, and asserts they match.
// =============================================================
`timescale 1ns / 1ps

module memory_tb;

  localparam AD_LINES = 16;
  localparam DATA_LINES = 8;

  logic rd_wr_bar;
  logic [AD_LINES-1:0] addr_bus;
  logic clk;
  logic cs;

  tri [DATA_LINES-1:0] data_bus;
  logic [DATA_LINES-1:0] data_drv;

  // Testbench only drives the bus during writes; the DUT drives
  // it during reads (see data_memory.sv's tri-state assign).
  assign data_bus = (!rd_wr_bar && cs) ? data_drv : 'z;

  memory #(
      .AD_LINES  (AD_LINES),
      .DATA_LINES(DATA_LINES)
  ) dut (
      .rd_wr_bar(rd_wr_bar),
      .addr_bus(addr_bus),
      .data_bus(data_bus),
      .clk(clk),
      .cs(cs)
  );

  // Clock generation: 10ns period
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Write task: assert cs+write, drive address/data, wait for a
  // clock edge so the DUT latches it, then release.
  task automatic mem_write(input [AD_LINES-1:0] wr_addr, input [DATA_LINES-1:0] wr_data);
    begin
      @(negedge clk);
      cs        = 1;
      rd_wr_bar = 0;
      addr_bus  = wr_addr;
      data_drv  = wr_data;

      @(posedge clk);  // write occurs here

      @(negedge clk);
      cs       = 0;
      data_drv = 'z;
    end
  endtask

  // Read task: assert cs+read, drive address, let the DUT's
  // combinational read settle, then sample the bus.
  task automatic mem_read(input [AD_LINES-1:0] rd_addr, output [DATA_LINES-1:0] rd_data);
    begin
      @(negedge clk);
      cs        = 1;
      rd_wr_bar = 1;
      addr_bus  = rd_addr;

      #1;  // allow combinational read to propagate
      rd_data = data_bus;

      @(negedge clk);
      cs = 0;
    end
  endtask

  logic [7:0] rdata;

  initial begin
    $dumpfile("memory.vcd");
    $dumpvars(0, memory_tb);

    cs        = 0;
    rd_wr_bar = 1;
    addr_bus  = 0;
    data_drv  = 'z;

    // Write some values
    mem_write(16'h0000, 8'hAA);
    mem_write(16'h0001, 8'h55);
    mem_write(16'h1234, 8'hDE);
    mem_write(16'hFFFF, 8'hAD);

    // Read them back
    mem_read(16'h0000, rdata);
    $display("Addr=0000 Data=%h Expected=AA", rdata);

    mem_read(16'h0001, rdata);
    $display("Addr=0001 Data=%h Expected=55", rdata);

    mem_read(16'h1234, rdata);
    $display("Addr=1234 Data=%h Expected=DE", rdata);

    mem_read(16'hFFFF, rdata);
    $display("Addr=FFFF Data=%h Expected=AD", rdata);

    // Assertions
    mem_read(16'h0000, rdata);
    assert (rdata == 8'hAA);

    mem_read(16'h0001, rdata);
    assert (rdata == 8'h55);

    mem_read(16'h1234, rdata);
    assert (rdata == 8'hDE);

    mem_read(16'hFFFF, rdata);
    assert (rdata == 8'hAD);

    $display("TEST PASSED");
    $finish;
  end

endmodule
