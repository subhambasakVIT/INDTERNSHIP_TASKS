`timescale 1ns / 1ps
module RAM_DESIGN #(parameter DATA_WIDTH = 8,parameter ADDR_WIDTH = 3) (
    input wire clk,            
    input wire we,             
    input wire en,              
    input wire [ADDR_WIDTH-1:0] addr, 
    input wire [DATA_WIDTH-1:0] din,  
    output reg [DATA_WIDTH-1:0] dout  
);
    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    always @(posedge clk) begin
        if (en) begin
            if (we)  
                mem[addr] <= din;   
            else  
                dout <= mem[addr];  
        end
    end

endmodule
