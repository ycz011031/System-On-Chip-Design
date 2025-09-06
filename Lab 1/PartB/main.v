`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/05/2025 06:18:33 PM
// Design Name: 
// Module Name: main
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


module main(

    input sysclk, // system clock
    
    input [3:0] btn, // Buttons
    input [1:0] sw, //slide switches
    
    output [3:0] led  // Individual LED Controls
    );
    
        
    MP1PTB MP1PTB(
        .clk(sysclk),
        
        .switches(sw),
        .buttons(btn),
        .leds(led)
        );
        
endmodule
