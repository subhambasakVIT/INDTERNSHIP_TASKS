`timescale 1ns / 1ps
//===========================================================
// Module      : ALU
// Description : 4-bit multi-operation Arithmetic Logic Unit
//               Supports 8 arithmetic/logical operations:
//               ADD, SUB, AND, OR, XOR, NOT, SHL, SHR
// Flags       : cout  -> carry/borrow out of ADD/SUB
//               zero  -> asserted when alu_out == 0
//===========================================================
module ALU (
    input  [3:0] A,
    input  [3:0] B,
    input  [2:0] OP,
    output reg [3:0] alu_out,
    output reg       cout,
    output           zero
);

    // Opcode map (3 bits -> 8 operations)
    localparam OP_ADD = 3'b000;   // A + B
    localparam OP_SUB = 3'b001;   // A - B
    localparam OP_AND = 3'b010;   // A & B
    localparam OP_OR  = 3'b011;   // A | B
    localparam OP_XOR = 3'b100;   // A ^ B
    localparam OP_NOT = 3'b101;   // ~A
    localparam OP_SHL = 3'b110;   // A << 1 (logical left shift)
    localparam OP_SHR = 3'b111;   // A >> 1 (logical right shift)

    reg [4:0] add_ext; // 5-bit to catch carry out of ADD
    reg [4:0] sub_ext; // 5-bit to catch borrow out of SUB

    always @(*) begin
        // defaults
        cout    = 1'b0;
        add_ext = 5'b0;
        sub_ext = 5'b0;

        case (OP)
            OP_ADD: begin
                add_ext = {1'b0, A} + {1'b0, B};
                alu_out = add_ext[3:0];
                cout    = add_ext[4];        // carry out
            end
            OP_SUB: begin
                sub_ext = {1'b0, A} - {1'b0, B};
                alu_out = sub_ext[3:0];
                cout    = (A < B);           // borrow flag
            end
            OP_AND:  alu_out = A & B;
            OP_OR:   alu_out = A | B;
            OP_XOR:  alu_out = A ^ B;
            OP_NOT:  alu_out = ~A;
            OP_SHL:  alu_out = A << 1;
            OP_SHR:  alu_out = A >> 1;
            default: alu_out = 4'b0000;
        endcase
    end

    assign zero = (alu_out == 4'b0000);

endmodule
