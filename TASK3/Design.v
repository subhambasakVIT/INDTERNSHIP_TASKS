`timescale 1ns / 1ps
//===========================================================
// Module      : pipeline_processor
// Description : 4-stage pipelined RISC processor (IF/ID/EX/WB)
//               Supports ADD, SUB, LOAD.
//
// ISA (8-bit instruction):
//   [7:6] opcode : 00=ADD  01=SUB  10=LOAD  11=NOP
//   [5:3] rd     : destination register (R0-R7)
//                  also acts as the first source operand for
//                  ADD/SUB (2-operand accumulate style: Rd = Rd OP Rs)
//   [2:0] rs/addr: ADD/SUB -> second source register index
//                  LOAD    -> immediate memory address (0-7)
//
// Hazard handling:
//   RAW hazards are resolved with combinational forwarding.
//   - EX-stage forward : bypasses the result of the instruction
//     currently in EX (1 instruction ahead) directly into the
//     ID-stage operand read, so back-to-back dependent
//     instructions need no stall.
//   - WB-stage forward : bypasses the result of the instruction
//     currently being written back (2 instructions ahead) to
//     cover the case where the register file write and a
//     dependent read would otherwise race in the same cycle.
//   Because EX has no separate MEM stage, LOAD results are
//   available for forwarding at the same point as ADD/SUB
//   results, so no load-use stall is required either.
//===========================================================
module pipeline_processor (
    input  wire       clk,
    input  wire       reset,
    output reg  [7:0] result,       // committed result of the instruction leaving WB
    output reg        result_valid  // high when 'result' corresponds to a real (non-NOP) instruction
);

    localparam OP_ADD = 2'b00;
    localparam OP_SUB = 2'b01;
    localparam OP_LD  = 2'b10;
    localparam OP_NOP = 2'b11;

    localparam IMEM_DEPTH = 256; // 8-bit PC -> supports 200+ instruction programs
    localparam DMEM_DEPTH = 8;   // matches 3-bit immediate address field

    reg [7:0] instruction_memory [0:IMEM_DEPTH-1];
    reg [7:0] data_memory        [0:DMEM_DEPTH-1];
    reg [7:0] registers          [0:7];

    reg [7:0] pc;

    // ---------------- IF/ID pipeline latch ----------------
    reg [7:0] IF_ID_instr;
    reg       IF_ID_valid;

    // ---------------- ID/EX pipeline latch -----------------
    reg [7:0] ID_EX_op1, ID_EX_op2;
    reg [2:0] ID_EX_rd;
    reg [2:0] ID_EX_addr;
    reg [1:0] ID_EX_opcode;
    reg       ID_EX_valid;

    // ---------------- EX/WB pipeline latch -----------------
    reg [7:0] EX_WB_result;
    reg [2:0] EX_WB_rd;
    reg       EX_WB_we;
    reg       EX_WB_valid;

    integer k;

    // =========================================================
    // IF stage
    // =========================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc          <= 8'b0;
            IF_ID_instr <= 8'b0;
            IF_ID_valid <= 1'b0;
        end else begin
            IF_ID_instr <= instruction_memory[pc];
            IF_ID_valid <= 1'b1;
            pc          <= pc + 1'b1;
        end
    end

    // =========================================================
    // ID stage: decode + register read with forwarding
    // =========================================================
    wire [1:0] id_opcode = IF_ID_instr[7:6];
    wire [2:0] id_rs1    = IF_ID_instr[5:3]; // also destination
    wire [2:0] id_rs2    = IF_ID_instr[2:0]; // src2 (ADD/SUB) or addr (LOAD)

    // EX-stage combinational result (computed below) is forwarded here
    wire [7:0] ex_result_comb;
    wire       ex_we_comb;

    function automatic [7:0] fwd_read(input [2:0] idx);
        begin
            if (ID_EX_valid && ex_we_comb && (ID_EX_rd == idx))
                fwd_read = ex_result_comb;                 // forward from EX (1 ahead)
            else if (EX_WB_valid && EX_WB_we && (EX_WB_rd == idx))
                fwd_read = EX_WB_result;                   // forward from WB (2 ahead)
            else
                fwd_read = registers[idx];                 // no hazard: register file
        end
    endfunction

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ID_EX_valid  <= 1'b0;
            ID_EX_opcode <= OP_NOP;
            ID_EX_rd     <= 3'b0;
            ID_EX_addr   <= 3'b0;
            ID_EX_op1    <= 8'b0;
            ID_EX_op2    <= 8'b0;
        end else begin
            ID_EX_valid  <= IF_ID_valid;
            ID_EX_opcode <= id_opcode;
            ID_EX_rd     <= id_rs1;
            ID_EX_addr   <= id_rs2;
            ID_EX_op1    <= fwd_read(id_rs1);
            ID_EX_op2    <= fwd_read(id_rs2);
        end
    end

    // =========================================================
    // EX stage (combinational ALU + memory read, registered below)
    // =========================================================
    reg [7:0] ex_result_r;
    always @(*) begin
        case (ID_EX_opcode)
            OP_ADD:  ex_result_r = ID_EX_op1 + ID_EX_op2;
            OP_SUB:  ex_result_r = ID_EX_op1 - ID_EX_op2;
            OP_LD:   ex_result_r = data_memory[ID_EX_addr];
            default: ex_result_r = 8'b0; // NOP
        endcase
    end
    assign ex_result_comb = ex_result_r;
    assign ex_we_comb     = ID_EX_valid && (ID_EX_opcode != OP_NOP);

    // =========================================================
    // EX/WB latch + WB stage (register file write)
    // =========================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (k = 0; k < 8; k = k + 1)
                registers[k] <= 8'b0;
            EX_WB_valid  <= 1'b0;
            EX_WB_we     <= 1'b0;
            EX_WB_rd     <= 3'b0;
            EX_WB_result <= 8'b0;
            result       <= 8'b0;
            result_valid <= 1'b0;
        end else begin
            // commit the instruction currently sitting in EX/WB (from last cycle)
            if (EX_WB_valid && EX_WB_we)
                registers[EX_WB_rd] <= EX_WB_result;
            result       <= EX_WB_result;
            result_valid <= EX_WB_valid && EX_WB_we;

            // latch this cycle's EX output for next cycle's WB
            EX_WB_valid  <= ID_EX_valid;
            EX_WB_we     <= ex_we_comb;
            EX_WB_rd     <= ID_EX_rd;
            EX_WB_result <= ex_result_comb;
        end
    end

endmodule
