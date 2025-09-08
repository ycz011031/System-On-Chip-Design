`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/07/2025 05:29:08 PM
// Design Name: 
// Module Name: Caesar_AXIL_S
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


module Caesar_AXIL_S(
      input  wire        aclk,
      input  wire        aresetn,
    
      // AXI-Lite
      input  wire        s_axi_awvalid,
      output reg         s_axi_awready,
      input  wire [31:0] s_axi_awaddr,
    
      input  wire        s_axi_wvalid,
      output reg         s_axi_wready,
      input  wire [31:0] s_axi_wdata,
      input  wire [3:0]  s_axi_wstrb,
    
      output reg         s_axi_bvalid,
      input  wire        s_axi_bready,
      output wire [1:0]  s_axi_bresp,
    
      input  wire        s_axi_arvalid,
      output wire        s_axi_arready,
      input  wire [31:0] s_axi_araddr,
    
      output wire        s_axi_rvalid,
      input  wire        s_axi_rready,
      output wire [31:0] s_axi_rdata,
      output wire [1:0]  s_axi_rresp,
    
      // Datapath view
      output reg signed [31:0] shift_data,
      output reg               shift_valid
);
            
    assign s_axi_arready = 1'b1;
    assign s_axi_rdata   = 32'd0;
    assign s_axi_rvalid  = 1'b1;
    assign s_axi_rresp = 2'b00;
    assign s_axi_bresp = 2'b00;

    always @(posedge aclk or negedge aresetn)begin
        if(~aresetn) begin
            s_axi_awready     <= 1'b1;
            s_axi_wready      <= 1'b1;
        end else begin
            s_axi_awready     <= 1'b1;
            s_axi_wready      <= 1'b1;
            if (s_axi_wvalid) begin
                if (s_axi_wstrb[0]) shift_data[7: 0] = s_axi_wdata[7: 0];
                if (s_axi_wstrb[1]) shift_data[15: 8] = s_axi_wdata[15: 8];
                if (s_axi_wstrb[2]) shift_data[23: 16] = s_axi_wdata[23: 16];
                if (s_axi_wstrb[3]) shift_data[31:24] = s_axi_wdata[31:24];
                s_axi_bvalid  <= 1'b1;
                shift_valid <= 1'b1;
            end else begin
                if (s_axi_bready) s_axi_bvalid <= 1'b0;
                if (shift_valid) shift_valid <= 1'b0;
            end
        end             
    end                    
endmodule
