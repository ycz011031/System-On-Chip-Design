`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/05/2025 07:09:45 PM
// Design Name: 
// Module Name: MP1PTB_sim
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


module MP1PTB_sim();
  // DUT I/O
  reg        sysclk;
  reg [3:0]  btn;
  reg [1:0]  sw;

  wire [3:0] led;
  
  main dut (
    .sysclk(sysclk),
    .btn(btn),
    .sw(sw),
    .led(led)
  );
  
  // Clock
  initial sysclk = 1'b0;
  always #5 sysclk = ~sysclk;
  
  task wait_posedges;
    input integer n;
    integer i;
    begin
      for (i=0; i<n; i=i+1) @(posedge sysclk);
    end
  endtask

  integer a, b;

  initial begin
    btn = 4'b0000;
    sw  = 2'b00;

    // Prime pipeline
    wait_posedges(6);

    for (a=0; a<4; a=a+1) begin
      @(posedge sysclk) btn <= 4'b1 << a;
      @(posedge sysclk) btn <= 4'b0;
      for (b=0; b<4; b=b+1) begin
          @(posedge sysclk) sw <= b[1:0];
          wait_posedges(1);
//          if ({led5_b, led4_b} !== sw) $display("ERROR: switch is %0b led is %0b", sw[1:0], {led5_b, led4_b});
       end
    end
    wait_posedges(1);
    $display("=== TEST COMPLETE ===");
    $finish;
  end

endmodule
