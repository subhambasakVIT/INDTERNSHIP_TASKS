`timescale 1ns / 1ps
module pipeline_processor(
    input clk, reset,
    output reg [7:0] result
);

    reg [7:0] instruction_memory [0:15];  // Declare inside module
    reg [7:0] data_memory [0:15];         // Declare inside module

    reg [7:0] IF_ID_instr;
    reg [7:0] ID_EX_instr, ID_EX_operand1, ID_EX_operand2;
    reg [7:0] EX_WB_result;
    
    reg [7:0] registers [0:7]; // 8 registers

    // Instruction Fetch (IF)
    reg [3:0] pc;
    always @(posedge clk or posedge reset) begin
        if (reset) pc <= 0;
        else begin
            IF_ID_instr <= instruction_memory[pc];
            pc <= pc + 1;
        end
    end

    // Instruction Decode (ID)
    always @(posedge clk) begin
        ID_EX_instr <= IF_ID_instr;
        ID_EX_operand1 <= registers[IF_ID_instr[5:3]];
        ID_EX_operand2 <= registers[IF_ID_instr[2:0]];
    end

    // Execute (EX)
    always @(posedge clk) begin
        case (ID_EX_instr[7:6])
            2'b00: EX_WB_result <= ID_EX_operand1 + ID_EX_operand2; // ADD
            2'b01: EX_WB_result <= ID_EX_operand1 - ID_EX_operand2; // SUB
            2'b10: EX_WB_result <= data_memory[ID_EX_operand1]; // LOAD
            default: EX_WB_result <= 0;
        endcase
    end

    // Write Back (WB)
    always @(posedge clk) begin
        registers[ID_EX_instr[5:3]] <= EX_WB_result;
        result <= EX_WB_result;
    end

endmodule
