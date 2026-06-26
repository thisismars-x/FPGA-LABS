module alu8 (
    input  wire [7:0] A,
    input  wire [7:0] B,
    input  wire [3:0] sel,

    output reg  [7:0] Result,
    output reg        Cout,
    output wire       Zero,
    output reg        Overflow
);

    reg [8:0] temp;

    always @(*) begin
        // Default values
        Result   = 8'b0;
        Cout     = 1'b0;
        Overflow = 1'b0;
        temp     = 9'b0;

        case (sel)

            // ADD
            4'b0000: begin
                temp     = {1'b0, A} + {1'b0, B};
                Result   = temp[7:0];
                Cout     = temp[8];
                Overflow = (A[7] == B[7]) &&
                           (Result[7] != A[7]);
            end

            // SUBTRACT
            4'b0001: begin
                temp     = {1'b0, A} - {1'b0, B};
                Result   = temp[7:0];
                Cout     = temp[8];
                Overflow = (A[7] != B[7]) &&
                           (Result[7] != A[7]);
            end

            // LOGICAL OPERATIONS
            4'b0010: Result = A & B;      // AND
            4'b0011: Result = A | B;      // OR
            4'b0100: Result = A ^ B;      // XOR
            4'b0101: Result = ~(A | B);   // NOR
            4'b0110: Result = ~(A & B);   // NAND
            4'b0111: Result = ~(A ^ B);   // XNOR
            4'b1000: Result = ~A;         // NOT

            // SHIFT OPERATIONS
            4'b1001: Result = A << 1;     // Shift left
            4'b1010: Result = A >> 1;     // Shift right

            // ROTATE OPERATIONS
            4'b1011: Result = {A[6:0], A[7]}; // Rotate left
            4'b1100: Result = {A[0], A[7:1]}; // Rotate right

            // MULTIPLY (lower 8 bits only)
            4'b1101: Result = A * B;

            // COMPARISONS
            4'b1110: Result = {7'b0, (A > B)};
            4'b1111: Result = {7'b0, (A == B)};

            default: Result = 8'b0;

        endcase
    end

    assign Zero = (Result == 8'b0);

endmodule
