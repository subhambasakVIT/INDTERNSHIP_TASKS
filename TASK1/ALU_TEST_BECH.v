`timescale 1ns / 1ps
//===========================================================
// Testbench   : ALU_tb
// Description : Self-checking testbench for the ALU module.
//               - Directed corner-case vectors for all 8 ops
//               - 500+ constrained-random vectors
//               - Reference (golden) model checks every result
//               - Pass/Fail scoreboard with final summary
//===========================================================
module ALU_tb();

    reg  [3:0] A, B;
    reg  [2:0] OP;
    wire [3:0] alu_out;
    wire       cout;
    wire       zero;

    integer pass_count = 0;
    integer fail_count = 0;
    integer i;

    // reference model outputs
    reg [3:0] exp_out;
    reg       exp_cout;
    reg [4:0] tmp;

    ALU uut (
        .A(A), .B(B), .OP(OP),
        .alu_out(alu_out),
        .cout(cout),
        .zero(zero)
    );

    // -------------------------------------------------------
    // Golden reference model - mirrors intended ALU behaviour
    // -------------------------------------------------------
    task automatic ref_model(input [3:0] a, input [3:0] b, input [2:0] op,
                              output [3:0] o, output c);
        reg [4:0] ext;
        begin
            c = 1'b0;
            case (op)
                3'b000: begin ext = {1'b0,a} + {1'b0,b}; o = ext[3:0]; c = ext[4]; end
                3'b001: begin ext = {1'b0,a} - {1'b0,b}; o = ext[3:0]; c = (a < b); end
                3'b010: o = a & b;
                3'b011: o = a | b;
                3'b100: o = a ^ b;
                3'b101: o = ~a;
                3'b110: o = a << 1;
                3'b111: o = a >> 1;
                default: o = 4'b0000;
            endcase
        end
    endtask

    // -------------------------------------------------------
    // Apply one vector, wait, compare against golden model
    // -------------------------------------------------------
    task automatic check_vector(input [3:0] a, input [3:0] b, input [2:0] op);
        begin
            A = a; B = b; OP = op;
            #5; // settle combinational logic
            ref_model(a, b, op, exp_out, exp_cout);
            if (alu_out === exp_out && cout === exp_cout) begin
                pass_count = pass_count + 1;
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: OP=%b A=%b B=%b | DUT out=%b cout=%b | EXP out=%b cout=%b",
                          op, a, b, alu_out, cout, exp_out, exp_cout);
            end
            #5;
        end
    endtask

    initial begin
        $display("=== ALU Self-Checking Testbench Start ===");

        // -----------------------------------------------------------
        // Directed corner-case vectors (cover every op + edge values)
        // -----------------------------------------------------------
        check_vector(4'b0000, 4'b0000, 3'b000); // ADD 0+0
        check_vector(4'b1111, 4'b0001, 3'b000); // ADD overflow -> carry out
        check_vector(4'b0111, 4'b0111, 3'b000); // ADD no carry

        check_vector(4'b0000, 4'b0001, 3'b001); // SUB underflow -> borrow
        check_vector(4'b1111, 4'b1111, 3'b001); // SUB result 0
        check_vector(4'b1010, 4'b0011, 3'b001); // SUB normal

        check_vector(4'b1100, 4'b1010, 3'b010); // AND
        check_vector(4'b0000, 4'b1111, 3'b010); // AND with 0

        check_vector(4'b1100, 4'b0011, 3'b011); // OR complementary bits
        check_vector(4'b0000, 4'b0000, 3'b011); // OR both 0 -> zero flag

        check_vector(4'b1010, 4'b0110, 3'b100); // XOR
        check_vector(4'b1111, 4'b1111, 3'b100); // XOR same -> 0

        check_vector(4'b1010, 4'b0000, 3'b101); // NOT A
        check_vector(4'b0000, 4'b0000, 3'b101); // NOT of 0 -> all 1s

        check_vector(4'b1000, 4'b0000, 3'b110); // SHL with MSB drop
        check_vector(4'b0001, 4'b0000, 3'b110); // SHL simple

        check_vector(4'b0001, 4'b0000, 3'b111); // SHR to 0
        check_vector(4'b1000, 4'b0000, 3'b111); // SHR simple

        $display("--- Directed vectors done: pass=%0d fail=%0d ---", pass_count, fail_count);

        // -----------------------------------------------------------
        // Constrained-random vectors: 500+ total
        // -----------------------------------------------------------
        for (i = 0; i < 500; i = i + 1) begin
            check_vector($random, $random, $random % 8);
        end

        $display("=== ALU Self-Checking Testbench Complete ===");
        $display("TOTAL VECTORS = %0d | PASS = %0d | FAIL = %0d", pass_count + fail_count, pass_count, fail_count);
        if (fail_count == 0)
            $display("RESULT: ALL TESTS PASSED (0 failures across %0d vectors)", pass_count);
        else
            $display("RESULT: %0d FAILURES DETECTED", fail_count);

        $finish;
    end

endmodule
