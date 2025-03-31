`timescale 1ns / 1ps
module fir_filter_tb;
    reg clk, rst;
    reg signed [7:0] x;
    wire signed [15:0] y;

    // Instantiate FIR Filter
    fir_filter uut (
        .clk(clk),
        .rst(rst),
        .x(x),
        .y(y)
    );

    // Generate Clock
    always #5 clk = ~clk;

    initial begin
        // Initialize
        clk = 0;
        rst = 1;
        x = 0;
        #10 rst = 0;
        
        // Apply test inputs
        #10 x = 8'h10;  // Input = 16
        #10 x = 8'h20;  // Input = 32
        #10 x = 8'h30;  // Input = 48
        #10 x = 8'h40;  // Input = 64
        #10 x = 8'h00;  // Input = 0
        #50 $finish;
    end

    initial begin
        $monitor("Time=%0t | x=%d | y=%d", $time, x, y);
    end
endmodule
