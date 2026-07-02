// =============================================================
// 8-bit ALU. All arithmetic sub-units (adder, subtractor,
// increment, decrement, shifters) run combinationally in
// parallel; the opcode just selects which result is latched
// into `result` on the clock edge. A 3-bit flag register tracks
// {Zero, Carry, Parity} for the last arithmetic op.
//
// opcode map:
//   0000 NOP    0001 ADD   0010 SUB   0011 INC
//   0100 DEC    0101 NOT   0110 SHL   0111 SHR
//   1000 GET FLAGS (result <= flags)
//   1001 SET FLAGS (flags <= operand1[2:0])
//   1010 AND    1011 OR    1100 XOR
// =============================================================
module ALU (
    input [3:0] opcode,
    input clk,
    reset,
    input [7:0] operand1,
    operand2,
    output reg [7:0] result
);

  wire [7:0] add_result, sub_result, inc_result, dec_result, left_shift_result, right_shift_result, cmp_result;
  wire add_carry, sub_carry, inc_carry, dec_carry;

  reg [2:0] flag;  //{Zero, Carry, Parity}
  // checkParity parity(.in(result), .out(flag[0]));

  // --- combinational arithmetic units (all computed every cycle,
  //     only the selected one gets used) ---
  bit8adder adder (
      .a(operand1),
      .b(operand2),
      .sum(add_result),
      .cin(1'b0),
      .cout(add_carry)
  );
  bit8subtractor subtractor (
      .a(operand1),
      .b(operand2),
      .diff(sub_result),
      .cin(1'b1),          // cin=1 completes two's-complement subtraction
      .cout(sub_carry)
  );
  bit8adder INC (
      .a(operand1),
      .b(8'b1),
      .sum(inc_result),
      .cin(1'b0),
      .cout(inc_carry)
  );
  bit8subtractor DEC (
      .a(operand1),
      .b(8'b1),
      .diff(dec_result),
      .cin(1'b1),
      .cout(dec_carry)
  );
  leftShift lshift (
      .in(operand1),
      .shift(operand2[2:0]),
      .out(left_shift_result)
  );
  rightShift rshift (
      .in(operand1),
      .shift(operand2[2:0]),
      .out(right_shift_result)
  );

  always @(posedge clk) begin

    if (reset) begin
      result <= 8'b0;
      flag   <= 3'b0;
    end else begin
      case (opcode)
        4'b0000: result <= result;  //NOP

        //Addition
        4'b0001: begin
          result  <= add_result;
          flag[0] <= ~^add_result;  // Parity: XNOR-reduce -> 1 if even # of 1s
          flag[1] <= add_carry;     // Carry
          flag[2] <= (add_result == 8'b0);  // Zero
        end

        //Subtraction
        4'b0010: begin
          result  <= sub_result;
          flag[0] <= ~^sub_result;  //Parity
          // sub_carry comes from the adder inside bit8subtractor;
          // it's inverted here because "borrow" is the logical
          // complement of the adder's carry-out for a - b.
          flag[1] <= ~sub_carry;  // Carry
          flag[2] <= (sub_result == 8'b0);  // Zero
        end

        //Incrementor
        4'b0011: begin
          result  <= inc_result;
          flag[0] <= ~^inc_result;  //Parity
          flag[1] <= inc_carry;  // Carry
          flag[2] <= (inc_result == 8'b0);  // Zero
        end

        //Decrementor
        4'b0100: begin
          result  <= dec_result;
          flag[0] <= ~^dec_result;  //Parity
          flag[1] <= dec_carry;  // Carry
          flag[2] <= (dec_result == 8'b0);  // Zero
        end

        //Complement
        4'b0101: begin
          result <= ~operand1;
        end

        //Left Shift
        4'b0110: begin
          result <= left_shift_result;
        end

        //Right Shift
        4'b0111: begin
          result <= right_shift_result;
        end

        //Get Flag
        4'b1000: begin
          result <= {5'b0, flag};
        end

        //Set Flag
        4'b1001: begin
          flag <= operand1[2:0];
        end

        //And
        4'b1010: begin
          result <= operand1 & operand2;
        end

        //OR
        4'b1011: begin
          result <= operand1 | operand2;
        end

        //XOR
        4'b1100: begin
          result <= operand1 ^ operand2;
        end

        default: ;  // NOP
      endcase
    end
  end
endmodule
