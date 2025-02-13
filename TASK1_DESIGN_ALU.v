`timescale 1ns / 1ps

module ALU(input [3:0] A,B , input [2:0] OP , output reg [3:0] alu_out );

//A and B are the input registers on which the operation will be done
//OP determines the Operation that willl take place 

always@(*)
    begin
        case(OP) //checks the value of OP and does the respective operation
            3'b000 : alu_out = 4'b0000;
            3'b001 : alu_out = A+B; //ADDITION
            3'b010 : alu_out = A-B; //SUBSTRACT
            3'b011 : alu_out = A & B; //BITWISE AND
            3'b100 : alu_out = A | B; //BITWISE OR
            3'B101 : alu_out = ~A; //COMPLIMET OF A
            3'b110 : alu_out = ~B; //COMPLIMENT OF B
            3'b111 : alu_out = 4'b000;
            default : alu_out = 4'b000; //DEFAULT
        endcase
    end  

endmodule
