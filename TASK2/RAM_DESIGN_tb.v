`timescale 1ns / 1ps
module RAM_DESIGN_tb;

    // Parameters
    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 3;

    // Testbench signals
    reg clk;
    reg we;
    reg en;
    reg [ADDR_WIDTH-1:0] addr;
    reg [DATA_WIDTH-1:0] din;
    wire [DATA_WIDTH-1:0] dout;

    // Instantiate the RAM module
    RAM_DESIGN #(DATA_WIDTH, ADDR_WIDTH) uut (
        .clk(clk),
        .we(we),
        .en(en),
        .addr(addr),
        .din(din),
        .dout(dout)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Test sequence
    initial begin
        $monitor("Time=%0t | Addr=%0d | WE=%b | DIN=%h | DOUT=%h", $time, addr, we, din, dout);
        
        clk = 0; en = 1; we = 0; addr = 0; din = 0;
        
        // Write Operations
        #10 we = 1; addr = 3'b000; din = 8'hAA;  // Write 0xAA at address 0
        #10 we = 1; addr = 3'b001; din = 8'hBB;  // Write 0xBB at address 1
        #10 we = 1; addr = 3'b010; din = 8'hCC;  // Write 0xCC at address 2
        #10 we = 1; addr = 3'b011; din = 8'hDD;  // Write 0xDD at address 3

        // Read Operations
        #10 we = 0; addr = 3'b000; // Read address 0
        #10 we = 0; addr = 3'b001; // Read address 1
        #10 we = 0; addr = 3'b010; // Read address 2
        #10 we = 0; addr = 3'b011; // Read address 3

        #20 $finish;
    end

endmodule

