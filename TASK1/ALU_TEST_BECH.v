`timescale 1ns / 1ps

module ALU_tb();
reg [3:0] A;
reg [3:0] B;
reg [2:0] OP;
wire [3:0] alu_out;

ALU uut(.A(A),.B(B),.OP(OP),.alu_out(alu_out));

initial 
    begin 
        OP=3'b000; A=4'b0011; B=4'b0001; 
        #10; 
        OP=3'b001; A=4'b0010; B=4'b0011; 
        #10; 
        OP=3'b010; A=4'b0101; B=4'b0100; 
        #10; 
        OP=3'b011; A=4'b1110; B=4'b1001; 
        #10; 
        OP=3'b100; A=4'b1111; B=4'b1100; 
        #10;
        OP=3'b101; A=4'b1000; B=4'b1011; 
        #10;
        OP=3'b110; A=4'b1100; B=4'b1000; 
        #10;
        OP=3'b111; A=4'b0011; B=4'b1101; 
        #10;
        $finish;
    end 
endmodule
