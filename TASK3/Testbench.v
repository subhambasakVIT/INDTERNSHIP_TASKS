`timescale 1ns / 1ps
module pipeline_tb;
    reg clk, reset;
    wire [7:0] result;

    // Instantiate the processor
    pipeline_processor uut (
        .clk(clk),
        .reset(reset),
        .result(result)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // Initialize clock and reset
        clk = 0;
        reset = 1;
        #10 reset = 0;
        
        // Load instructions into memory inside the processor
        uut.instruction_memory[0] = 8'b00001001; // ADD R1, R0, R1
        uut.instruction_memory[1] = 8'b01001101; // SUB R3, R2, R1
        uut.instruction_memory[2] = 8'b10000100; // LOAD R1, MEM[4]
        uut.instruction_memory[3] = 8'b00010110; // ADD R2, R2, R6
        uut.instruction_memory[4] = 8'b00000000; // NOP

        // Load data memory
        uut.data_memory[4] = 8'b00001010; // MEM[4] = 10

        // Monitor values
        $monitor("Time: %d, Result: %d", $time, result);
        
        #50 $finish; // End simulation after 50 time units
    end
endmodule
