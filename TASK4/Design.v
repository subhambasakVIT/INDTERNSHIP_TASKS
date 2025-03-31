`timescale 1ns / 1ps
module fir_filter (
    input clk,
    input rst,
    input signed [7:0] x,  // 8-bit input
    output reg signed [15:0] y  // 16-bit output to prevent overflow
);
    reg signed [7:0] coeff [0:3];  // 4 filter coefficients
    reg signed [7:0] delay_line [0:3];  // Delay elements
    integer i;
    
    initial begin
        coeff[0] = 8'h02;  // Example coefficients
        coeff[1] = 8'h04;
        coeff[2] = 8'h04;
        coeff[3] = 8'h02;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            y <= 0;
            for (i = 0; i < 4; i = i + 1) delay_line[i] <= 0;
        end else begin
            // Shift delay line
            for (i = 3; i > 0; i = i - 1)
                delay_line[i] <= delay_line[i-1];
            delay_line[0] <= x;
            
            // Compute FIR filter output
            y <= (coeff[0] * delay_line[0]) + 
                 (coeff[1] * delay_line[1]) + 
                 (coeff[2] * delay_line[2]) + 
                 (coeff[3] * delay_line[3]);
        end
    end
endmodule
