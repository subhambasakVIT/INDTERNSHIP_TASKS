`timescale 1ns / 1ps
module RAM_DESIGN_tb;

    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 3;
    localparam DEPTH = (1 << ADDR_WIDTH);

    reg  clk;
    reg  we;
    reg  en;
    reg  [ADDR_WIDTH-1:0] addr;
    reg  [DATA_WIDTH-1:0] din;
    wire [DATA_WIDTH-1:0] dout;

    // shadow/reference memory model used to predict expected reads
    reg [DATA_WIDTH-1:0] ref_mem [0:DEPTH-1];

    integer i;
    integer pass_count = 0;
    integer fail_count = 0;

    RAM_DESIGN #(DATA_WIDTH, ADDR_WIDTH) uut (
        .clk(clk), .we(we), .en(en),
        .addr(addr), .din(din), .dout(dout)
    );

    // Clock generation
    always #5 clk = ~clk;

    // -----------------------------------------------------------
    // Drive a write cycle: sampled on the following posedge
    // -----------------------------------------------------------
    task automatic do_write(input [ADDR_WIDTH-1:0] a, input [DATA_WIDTH-1:0] d);
        begin
            @(negedge clk);
            en = 1; we = 1; addr = a; din = d;
            ref_mem[a] = d; // update golden model in lockstep
            @(posedge clk);
        end
    endtask

    // -----------------------------------------------------------
    // Drive a read cycle and check dout (registered, so the
    // valid data appears after the *next* posedge) against the
    // golden model
    // -----------------------------------------------------------
    task automatic do_read_check(input [ADDR_WIDTH-1:0] a);
        begin
            @(negedge clk);
            en = 1; we = 0; addr = a;
            @(posedge clk);
            #1; // allow non-blocking dout update to settle
            if (dout === ref_mem[a]) begin
                pass_count = pass_count + 1;
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: READ addr=%0d | DUT dout=%h | EXP=%h", a, dout, ref_mem[a]);
            end
        end
    endtask

    // -----------------------------------------------------------
    // en=0: port idle, dout must hold its previous value
    // -----------------------------------------------------------
    task automatic check_hold(input [DATA_WIDTH-1:0] held_val);
        begin
            @(negedge clk);
            en = 0; we = 0;
            @(posedge clk);
            #1;
            if (dout === held_val) begin
                pass_count = pass_count + 1;
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: HOLD check | DUT dout=%h | EXP=%h", dout, held_val);
            end
        end
    endtask

    initial begin
        $display("=== SRAM Self-Checking Testbench Start (DEPTH=%0d, WIDTH=%0d) ===", DEPTH, DATA_WIDTH);
        clk = 0; en = 0; we = 0; addr = 0; din = 0;

        // -----------------------------------------------------------
        // 1) Full sweep: write a unique pattern to every address
        // -----------------------------------------------------------
        for (i = 0; i < DEPTH; i = i + 1)
            do_write(i[ADDR_WIDTH-1:0], (8'hA0 + i));

        // -----------------------------------------------------------
        // 2) Full sweep: read back every address, verify coherency
        //    across the ENTIRE address range
        // -----------------------------------------------------------
        for (i = 0; i < DEPTH; i = i + 1)
            do_read_check(i[ADDR_WIDTH-1:0]);

        $display("--- Full-range write/read sweep done: pass=%0d fail=%0d ---", pass_count, fail_count);

        // -----------------------------------------------------------
        // 3) Overwrite coherency: rewrite address 0 and last address,
        //    confirm new data overrides old data (not stale)
        // -----------------------------------------------------------
        do_write(0, 8'hFF);
        do_write(DEPTH-1, 8'h11);
        do_read_check(0);
        do_read_check(DEPTH-1);

        // -----------------------------------------------------------
        // 4) Back-to-back write-then-read on the SAME address
        // -----------------------------------------------------------
        do_write(2, 8'h5A);
        do_read_check(2);

        // -----------------------------------------------------------
        // 5) en=0 hold-state check: last read value must persist
        //    while the port is disabled
        // -----------------------------------------------------------
        check_hold(8'h5A);

        $display("=== SRAM Self-Checking Testbench Complete ===");
        $display("TOTAL CHECKS = %0d | PASS = %0d | FAIL = %0d", pass_count + fail_count, pass_count, fail_count);
        if (fail_count == 0)
            $display("RESULT: ALL TESTS PASSED - read/write coherency verified across all %0d addresses", DEPTH);
        else
            $display("RESULT: %0d FAILURES DETECTED", fail_count);

        $finish;
    end

endmodule
