`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/05/2025 05:53:23 PM
// Design Name: 
// Module Name: MP1PT1_sim
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


module MP1PTA_sim();
  // DUT I/O
  reg        sysclk;
  reg [3:0]  btn;
  reg [1:0]  sw;

  wire       led4_b, led4_g, led4_r;
  wire       led5_b, led5_g, led5_r;
  wire [3:0] led;

  // DUT instance
  main dut (
    .sysclk(sysclk),
    .btn(btn),
    .sw(sw),
    .led4_b(led4_b), .led4_g(led4_g), .led4_r(led4_r),
    .led5_b(led5_b), .led5_g(led5_g), .led5_r(led5_r),
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

  integer a;

  initial begin
    btn = 4'b0000;
    sw  = 2'b00;

    // Prime pipeline
    wait_posedges(6);

    for (a=0; a<4; a=a+1) begin
      @(posedge sysclk) sw <= a[1:0];
      wait_posedges(4);
      if ({led5_b, led4_b} !== sw) $display("ERROR: switch is %0b led is %0b", sw[1:0], {led5_b, led4_b});
    end
    $display("=== TEST COMPLETE ===");
    $finish;
  end

endmodule
