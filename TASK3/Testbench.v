`timescale 1ns / 1ps
//===========================================================
// Testbench   : pipeline_tb
// Description : Self-checking testbench for the 4-stage
//               pipelined processor.
//
//               Method: a golden, purely-sequential (non-
//               pipelined) reference model executes the same
//               instruction stream in program order. Because
//               correct forwarding makes pipelined execution
//               observationally equivalent to sequential
//               execution, the DUT's committed result stream
//               (with its fixed 4-cycle IF->ID->EX->WB
//               latency, since this design never stalls) must
//               match the golden model exactly, instruction
//               for instruction.
//
//               Test content:
//                 - Directed back-to-back RAW hazard sequences
//                   (distance-1 EX forward and distance-2 WB
//                   forward, including a hazard across a NOP)
//                 - 200+ pseudo-random ADD/SUB/LOAD/NOP
//                   instructions with register indices biased
//                   into a small pool (R0-R3) to maximize
//                   hazard density
//===========================================================
module pipeline_tb;

    localparam OP_ADD = 2'b00;
    localparam OP_SUB = 2'b01;
    localparam OP_LD  = 2'b10;
    localparam OP_NOP = 2'b11;

    localparam NUM_DIRECTED = 12;
    localparam NUM_RANDOM   = 220;
    localparam TOTAL        = NUM_DIRECTED + NUM_RANDOM;

    reg clk, reset;
    wire [7:0] result;
    wire       result_valid;

    pipeline_processor uut (
        .clk(clk),
        .reset(reset),
        .result(result),
        .result_valid(result_valid)
    );

    always #5 clk = ~clk;

    // instruction stream + golden model bookkeeping
    reg [7:0] instr_stream [0:TOTAL-1];
    reg [7:0] dmem_init    [0:7];
    reg [7:0] gold_result  [0:TOTAL-1];
    reg       gold_valid   [0:TOTAL-1];

    reg [7:0] gold_regs [0:7];

    integer i, e, idx;
    integer pass_count = 0;
    integer fail_count = 0;

    // -----------------------------------------------------------
    // Build one instruction word
    // -----------------------------------------------------------
    function automatic [7:0] mk_instr(input [1:0] op, input [2:0] rd, input [2:0] rs2);
        mk_instr = {op, rd, rs2};
    endfunction

    // unsigned bounded random helper (avoids negative $random % n)
    function automatic [31:0] rnd_u(input [31:0] modulus);
        reg [31:0] raw;
        begin
            raw   = $random;
            rnd_u = raw % modulus;
        end
    endfunction

    // -----------------------------------------------------------
    // Golden sequential reference model
    // -----------------------------------------------------------
    task automatic run_golden_model;
        reg [1:0] op;
        reg [2:0] rd, rs2;
        reg [7:0] val;
        begin
            for (i = 0; i < 8; i = i + 1)
                gold_regs[i] = 8'b0;

            for (i = 0; i < TOTAL; i = i + 1) begin
                op  = instr_stream[i][7:6];
                rd  = instr_stream[i][5:3];
                rs2 = instr_stream[i][2:0];
                case (op)
                    OP_ADD: begin
                        val = gold_regs[rd] + gold_regs[rs2];
                        gold_regs[rd] = val;
                        gold_result[i] = val; gold_valid[i] = 1'b1;
                    end
                    OP_SUB: begin
                        val = gold_regs[rd] - gold_regs[rs2];
                        gold_regs[rd] = val;
                        gold_result[i] = val; gold_valid[i] = 1'b1;
                    end
                    OP_LD: begin
                        val = dmem_init[rs2];
                        gold_regs[rd] = val;
                        gold_result[i] = val; gold_valid[i] = 1'b1;
                    end
                    default: begin // NOP
                        gold_result[i] = 8'bx; gold_valid[i] = 1'b0;
                    end
                endcase
            end
        end
    endtask

    initial begin
        $display("=== Pipelined RISC Processor Self-Checking Testbench Start ===");
        clk = 0; reset = 1;

        // clear instruction memory to NOP so any stray fetch past the
        // programmed region never reads 'x'
        for (i = 0; i < 256; i = i + 1)
            uut.instruction_memory[i] = mk_instr(OP_NOP, 3'b0, 3'b0);

        // deterministic, distinct data-memory contents
        dmem_init[0] = 8'd10; dmem_init[1] = 8'd20; dmem_init[2] = 8'd5;
        dmem_init[3] = 8'd7;  dmem_init[4] = 8'd99; dmem_init[5] = 8'd3;
        dmem_init[6] = 8'd42; dmem_init[7] = 8'd1;
        for (i = 0; i < 8; i = i + 1)
            uut.data_memory[i] = dmem_init[i];

        // -----------------------------------------------------------
        // Directed hazard sequences
        // -----------------------------------------------------------
        instr_stream[0]  = mk_instr(OP_LD,  1, 0); // R1 = MEM[0] = 10
        instr_stream[1]  = mk_instr(OP_LD,  2, 1); // R2 = MEM[1] = 20
        instr_stream[2]  = mk_instr(OP_ADD, 1, 2); // R1 = R1+R2  (EX-fwd R2, WB-fwd R1) dist1/dist2
        instr_stream[3]  = mk_instr(OP_SUB, 1, 2); // R1 = R1-R2  (EX-fwd R1, WB-fwd R2)
        instr_stream[4]  = mk_instr(OP_NOP, 0, 0);
        instr_stream[5]  = mk_instr(OP_ADD, 3, 1); // R3 = R3+R1  (WB-fwd R1 across NOP gap)
        instr_stream[6]  = mk_instr(OP_LD,  4, 2); // R4 = MEM[2] = 5
        instr_stream[7]  = mk_instr(OP_ADD, 4, 4); // R4 = R4+R4  (EX-fwd R4, self-dependent)
        instr_stream[8]  = mk_instr(OP_SUB, 4, 4); // R4 = R4-R4  (EX-fwd R4 -> expect 0)
        instr_stream[9]  = mk_instr(OP_ADD, 5, 4); // R5 = R5+R4  (WB-fwd R4)
        instr_stream[10] = mk_instr(OP_ADD, 1, 3); // R1 = R1+R3
        instr_stream[11] = mk_instr(OP_SUB, 2, 1); // R2 = R2-R1

        // -----------------------------------------------------------
        // 200+ pseudo-random instructions, register pool biased to
        // R0-R3 to keep hazard density high
        // -----------------------------------------------------------
        for (i = NUM_DIRECTED; i < TOTAL; i = i + 1) begin
            // $random is signed; cast through an unsigned reg before
            // modulo so negative draws can't skip every case branch
            case (rnd_u(5))
                0: instr_stream[i] = mk_instr(OP_ADD, rnd_u(4), rnd_u(4));
                1: instr_stream[i] = mk_instr(OP_SUB, rnd_u(4), rnd_u(4));
                2: instr_stream[i] = mk_instr(OP_LD,  rnd_u(4), rnd_u(8));
                3: instr_stream[i] = mk_instr(OP_ADD, rnd_u(4), rnd_u(4));
                4: instr_stream[i] = mk_instr(OP_NOP, 3'b0, 3'b0);
            endcase
        end

        // load the built stream into the DUT's instruction memory
        for (i = 0; i < TOTAL; i = i + 1)
            uut.instruction_memory[i] = instr_stream[i];

        run_golden_model;

        // -----------------------------------------------------------
        // Release reset and run, checking the committed result each
        // cycle against the golden model (fixed 4-cycle latency,
        // no stalls in this design)
        // -----------------------------------------------------------
        #10 reset = 0;

        for (e = 1; e <= TOTAL + 6; e = e + 1) begin
            @(posedge clk);
            #1;
            idx = e - 4;
            if (idx >= 0 && idx < TOTAL) begin
                if (result_valid !== gold_valid[idx]) begin
                    fail_count = fail_count + 1;
                    $display("FAIL[%0d]: result_valid mismatch DUT=%b EXP=%b (instr=%b)",
                              idx, result_valid, gold_valid[idx], instr_stream[idx]);
                end else if (gold_valid[idx] && (result !== gold_result[idx])) begin
                    fail_count = fail_count + 1;
                    $display("FAIL[%0d]: result=%0d EXP=%0d (instr=%b)",
                              idx, result, gold_result[idx], instr_stream[idx]);
                end else begin
                    pass_count = pass_count + 1;
                end
            end
        end

        $display("=== Pipelined RISC Processor Testbench Complete ===");
        $display("TOTAL INSTRUCTIONS = %0d | PASS = %0d | FAIL = %0d", TOTAL, pass_count, fail_count);
        if (fail_count == 0)
            $display("RESULT: ALL TESTS PASSED - RAW hazards correctly resolved across %0d instructions", TOTAL);
        else
            $display("RESULT: %0d FAILURES DETECTED", fail_count);

        $finish;
    end

endmodule
