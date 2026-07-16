// regfile.v
// 8 x 8-bit register file with two read ports and one write port.
// Register 6 is hard-wired to the constant 1 and register 7 is
// hard-wired to the constant 0; writes to either are ignored.
// (Functionally identical to the original "refile" module.)

module regfile_unit(
    input        clk,
    input  [2:0] rd_addr1,
    input  [2:0] rd_addr2,
    input  [2:0] wr_addr,
    input  [7:0] wr_data,
    input        wr_en,
    output reg [7:0] rd_data1,
    output reg [7:0] rd_data2
    );

    reg [7:0] regmem [0:7];
    integer k;

    initial begin
        for (k = 0; k < 8; k = k + 1)
            regmem[k] = 8'b0;
    end

    always @(posedge clk) begin
        if (wr_en) begin
            case (wr_addr)
                3'd6: regmem[6] <= 8'd1;   // constant register, ignores writes
                3'd7: regmem[7] <= 8'd0;   // constant register, ignores writes
                default: regmem[wr_addr] <= wr_data;
            endcase
        end
    end

    always @(*) begin
        case (rd_addr1)
            3'd6: rd_data1 = 8'd1;
            3'd7: rd_data1 = 8'd0;
            default: rd_data1 = regmem[rd_addr1];
        endcase

        case (rd_addr2)
            3'd6: rd_data2 = 8'd1;
            3'd7: rd_data2 = 8'd0;
            default: rd_data2 = regmem[rd_addr2];
        endcase
    end

endmodule
