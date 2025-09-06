`timescale 1ns / 1ps

module main(

    input sysclk, // system clock
    
    input [3:0] btn, // Buttons
    input [1:0] sw, //slide switches
    
    output led4_b, led4_g, led4_r, // LD4 RGB LED Controls
    output led5_b, led5_g, led5_r, // LD5 RGB LED Controls
    
    output [3:0] led  // Individual LED Controls
    );
    
    
    wire [1:0] LED_Bs;
    assign led4_b = LED_Bs[0];
    assign led5_b = LED_Bs[1];
    
    MP1PTA MP1PTA(
        .clk(sysclk),
        
        .switches(sw),
        .LED_Bs(LED_Bs)
        );      
        

    
endmodule