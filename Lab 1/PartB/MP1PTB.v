`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/05/2025 06:19:08 PM
// Design Name: 
// Module Name: MP1PTB
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module MP1PTB(
   input wire clk,
        
   input wire [1:0] switches,
   input wire [3:0] buttons,
   output reg [3:0] leds
   );
    
    reg [1:0] mode = 0;
    reg [3:0] state = 0;
    //mode and state update
    always @(posedge clk) begin
        case (buttons)
            4'b0001 : mode <= 2'b00;
            4'b0010 : mode <= 2'b01;
            4'b0100 : mode <= 2'b10;
            4'b1000 : mode <= 2'b11;
            default : mode <= mode;
        endcase
        case (switches)
            2'b00   : state <= 4'b0001;
            2'b01   : state <= 4'b0011;
            2'b10   : state <= 4'b0111;
            2'b11   : state <= 4'b1111;
        endcase
    end
    //led output
    always @(*) begin
        case (mode)
            2'b00   : leds = state;
            2'b01   : leds = state >> 2;
            2'b10   : leds = {state[0], state[3:1]};
            2'b11   : leds = ~state;
            default : leds = state;
        endcase
    end
endmodule
