`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/31/2025 08:01:55 PM
// Design Name: 
// Module Name: MP1PTA
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


module MP1PTA(
    input wire        clk,
    
    input  wire [1:0] switches,
    output wire [1:0] LED_Bs

    );
    
    reg [1:0] registers [2:0];
    assign LED_Bs[0] = registers[2][0];
    assign LED_Bs[1] = registers[2][1];
    
    always @(posedge clk) begin
        registers[0] <= switches;
        registers[1] <= registers[0];
        registers[2] <= registers[1];
    end
    
    
endmodule
