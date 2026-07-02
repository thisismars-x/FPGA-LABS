// =============================================================
// Simple microcoded CPU control unit. Cycles through
// FETCH -> DECODE -> [FETCH_ADDR] -> EXECUTE -> [STORE] -> FETCH,
// generating the control lines for memory, the register bank,
// and the ALU.
//
// Instruction format (top bits of `ir` select the type):
//   ir[7] = 1                 -> ARITH instruction (ALU op)
//   ir[7] = 0, ir[6] = 0      -> SWAP instruction (swap 2 registers)
//   ir[7] = 0, ir[6] = 1      -> memory/jump instruction, further
//                                 split by ir[5] into:
//       ir[5] = 0 -> MEMORY_OPERATION (load/store, uses ir[4] to
//                    pick direction: MEMORY_2_REG or REG_2_MEMORY)
//       ir[5] = 1 -> conditional/unconditional JUMP, condition
//                    selected by ir[4:2] against the flag register
// =============================================================
module control_unit #(
    parameter int AD_LINES   = 16,
    parameter int DATA_LINES = 8
) (
    // common signals
    input logic clk,
    input logic reset,
    input wire [DATA_LINES -1 : 0] acc_in,
    output logic [AD_LINES - 1 : 0] addr_bus,
    inout wire [DATA_LINES -1 : 0] data_bus,
    // memory control lines and signals.
    output logic mem_cs,
    output logic mem_rd_wr_bar,

    // register bank control lines and signals
    output logic [2:0] reg_sel[1:0],
    output logic reg_alu_db_bar,
    output logic reg_rd_wr_bar,
    output logic swp,
    output logic reg_cs,

    // alu control bits
    output logic [3:0] alu_sel
);

  reg [ AD_LINES - 1 : 0] pc;             // program counter
  reg [  AD_LINES -1 : 0] mem_address;    // assembled 16-bit address (for load/store/jump)
  reg [DATA_LINES -1 : 0] ir;             // instruction register (latched opcode byte)
  reg [DATA_LINES -1 : 0] flag_register;  // snapshot of ALU flags, used for conditional jumps

  // main FSM state
  typedef enum {
    FETCH,       // read opcode byte from memory at pc
    DECODE,      // figure out what kind of instruction it is
    EXECUTE,     // perform the operation (ALU op, swap, or jump)
    FETCH_ADDR,  // for 2-byte instructions: fetch the address operand
    STORE        // write the EXECUTE result back to a register/memory
  } state_t;
  state_t state;

  // instruction category, decided in DECODE
  typedef enum {
    SWAP,
    JUMP,
    MEMORY_OPERATION,
    ARITH
  } inst_t;
  inst_t instruction_type;

  // for MEMORY_OPERATION / ARITH: where does the STORE stage write to?
  typedef enum {
    MEMORY_2_REG,
    REG_2_MEMORY,
    ALU_2_REG
  } store_t;
  store_t store_type;

  // for 2-byte instructions (address operands), tracks which of
  // the two address bytes we're currently fetching
  typedef enum {
    FIRST,
    SECOND
  } fetch_number_t;
  fetch_number_t fetch_number;

  logic [DATA_LINES -1:0] recv_data;
  logic [DATA_LINES -1:0] acc_data;
  assign recv_data = data_bus;
  assign acc_data  = acc_in;

  initial begin
    pc <= 16'h0;
    state <= FETCH;
  end

  // asynchronous-style reset block (triggered on reset's rising edge)
  always_ff @(posedge reset) begin
    pc <= 16'h0;
    ir <= 8'h0;
    mem_address <= 16'h0;
    flag_register <= 8'h0;
    state <= FETCH;
  end

  always_ff @(posedge clk) begin
    // default (de-asserted) values each cycle; states below override
    // whichever lines they actually need
    mem_cs         <= 0;
    mem_rd_wr_bar  <= 1;

    reg_cs         <= 0;
    swp            <= 0;
    reg_rd_wr_bar  <= 1;
    reg_alu_db_bar <= 0;
    case (state)

      // ---- FETCH: read the opcode byte pointed to by pc ----
      FETCH: begin
        mem_cs <= 1;
        addr_bus <= pc;
        mem_rd_wr_bar <= 1'b1;  // read
        pc <= pc + 1;
        state <= DECODE;
      end

      // ---- DECODE: classify the opcode byte just fetched ----
      DECODE: begin
        ir = recv_data;
        case (ir[7:7])
          // ir[7]=0: either a SWAP or a load/store/jump instruction
          1'b0: begin
            case (ir[6:6])
              // ir[7:6]=00 -> SWAP instruction.
              // register selects are ir[5:3] and ir[2:0].
              1'b0: begin
                instruction_type <= SWAP;
                state <= EXECUTE;
              end
              // ir[7:6]=01 -> load/store/jump; these are 3-byte
              // instructions (opcode + 2 address bytes), so go
              // fetch the address next.
              1'b1: begin
                fetch_number <= FIRST;
                case (ir[5:5])
                  // ir[5]=0 -> memory load/store
                  1'b0: begin
                    case (ir[4:4])
                      1'b1: begin
                        store_type <= MEMORY_2_REG;  // load
                      end
                      1'b0: begin
                        store_type <= REG_2_MEMORY;  // store
                      end
                      default: begin
                        state <= FETCH;
                      end
                    endcase
                    instruction_type <= MEMORY_OPERATION;
                  end
                  // ir[5]=1 -> jump, conditioned on flag_register
                  // (which is refreshed from the accumulator here)
                  1'b1: begin
                    flag_register = acc_data;
                    case (ir[4:2])
                      // unconditional jump
                      3'b000: begin
                        instruction_type <= JUMP;
                      end
                      //JC  - jump if carry flag set
                      3'b001: begin
                        if (flag_register[1:1]) begin
                          instruction_type <= JUMP;
                        end
                      end
                      //JNC - jump if carry flag clear
                      3'b010: begin
                        if (!flag_register[1:1]) begin
                          instruction_type <= JUMP;
                        end
                      end
                      // JZ - jump if zero flag set
                      3'b011: begin
                        if (flag_register[2:2]) begin
                          instruction_type <= JUMP;
                        end
                      end
                      //JNZ - jump if zero flag clear
                      3'b100: begin
                        if (!flag_register[2:2]) begin
                          instruction_type <= JUMP;
                        end
                      end
                      default: begin
                        state <= FETCH;
                      end
                    endcase
                  end
                  default: begin
                    state <= FETCH;
                  end
                endcase
                state <= FETCH_ADDR;
              end
              default: begin
              end
            endcase
          end

          // ir[7]=1 -> ARITH: 3 source-register bits + 4 ALU-opcode bits
          1'b1: begin
            instruction_type <= ARITH;
            state <= EXECUTE;
          end
          default: begin
            state <= FETCH;
          end
        endcase
      end

      // ---- FETCH_ADDR: pull in the 2-byte address operand,
      //      one byte per cycle ----
      FETCH_ADDR: begin
        case (fetch_number)
          FIRST: begin
            mem_cs <= 1;
            addr_bus <= pc;
            mem_rd_wr_bar <= 1'b1;
            pc <= pc + 1;
            fetch_number <= SECOND;
          end
          SECOND: begin
            mem_address[AD_LINES-DATA_LINES-1 : 0] <= recv_data;  //lower order address byte
            mem_cs <= 1;
            addr_bus <= pc;
            mem_rd_wr_bar <= 1'b1;
            pc <= pc + 1;
            state <= EXECUTE;
          end
          default: begin
            state <= FETCH;
          end
        endcase
      end

      // ---- EXECUTE: dispatch based on instruction_type ----
      EXECUTE: begin
        // for JUMP/MEMORY_OPERATION the second address byte just
        // arrived; latch the upper half of the address here
        if (instruction_type == JUMP || instruction_type == MEMORY_OPERATION) begin
          mem_address[AD_LINES-1 : AD_LINES-DATA_LINES] <= recv_data;  //higher order address
        end
        case (instruction_type)
          SWAP: begin
            reg_sel[0] <= ir[5:3];
            reg_sel[1] <= ir[2:0];
            reg_cs <= 1;
            swp <= 1;
            state <= FETCH;
          end
          ARITH: begin
            alu_sel <= ir[6:3];
            reg_sel[0] <= 3'b000;
            reg_sel[1] <= ir[2:0];
            reg_cs <= 1;
            reg_alu_db_bar <= 1;
            reg_rd_wr_bar <= 1;
            state <= STORE;
            store_type <= ALU_2_REG;
          end
          MEMORY_OPERATION: begin
            state <= STORE;
          end
          JUMP: begin
            // reassemble the target address from the two fetched
            // bytes and load it into pc
            pc <= {recv_data, mem_address[DATA_LINES-1:0]};
            state <= FETCH;
          end
          default: begin
            state <= FETCH;
          end
        endcase
      end

      // ---- STORE: write the EXECUTE-stage result to its destination ----
      STORE: begin
        case (store_type)
          ALU_2_REG: begin
            reg_cs <= 1;
            reg_rd_wr_bar <= 0;
            reg_alu_db_bar <= 1;  // source is the ALU output, not the data bus
            reg_sel[0] <= 3'b000;
          end
          MEMORY_2_REG: begin
            reg_cs <= 1;
            reg_rd_wr_bar <= 0;
            reg_alu_db_bar <= 0;  // source is the data bus (memory)
            reg_sel[0] <= 3'b000;

            addr_bus <= mem_address;
            mem_cs <= 1;
            mem_rd_wr_bar <= 1;  // read from memory
          end
          REG_2_MEMORY: begin
            reg_cs <= 1;
            reg_rd_wr_bar <= 1;  // read from register (drive it onto the bus)
            reg_alu_db_bar <= 0;
            reg_sel[0] <= 3'b000;

            addr_bus <= mem_address;
            mem_cs <= 1;
            mem_rd_wr_bar <= 0;  // write to memory
          end
          default: begin
            state <= FETCH;
          end
        endcase
        state <= FETCH;
      end
      default: state <= FETCH;
    endcase
  end
endmodule
