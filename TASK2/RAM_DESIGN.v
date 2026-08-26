`timescale 1ns / 1ps
module RAM_DESIGN #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 3
) (
    input  wire                  clk,
    input  wire                  we,     // write enable
    input  wire                  en,     // chip/port enable
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [DATA_WIDTH-1:0] din,
    output reg  [DATA_WIDTH-1:0] dout
);

    localparam DEPTH = (1 << ADDR_WIDTH);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge clk) begin
        if (en) begin
            if (we)
                mem[addr] <= din;   // write cycle
            else
                dout <= mem[addr];  // read cycle (registered output)
        end
        // en == 0: port idle, dout and memory both hold state
    end

endmodule
