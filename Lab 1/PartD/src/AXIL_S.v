`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/06/2025 02:23:30 PM
// Design Name: 
// Module Name: AXIL_S
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision: 0.01
// Revision 0.01 - Supports MOSI only, as the system only requires MOSI
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module AXIL_S(
    //axi global signals
    input ACLK,
    input ARESETN,
    
    //Read address
    input  [31:0] ARADDR,
    input  [3:0]  ARCACHE,
    input  [2:0]  ARPROT,
    input         ARVALID,
    output        ARREADY,
    
    //Read data
    output [31:0] RDATA,
    output        RRESP,
    output        RVALID,
    input         RREADY,
    
    //Write address
    input  [31:0] AWADDR,
    input  [2:0]  AWPROT,
    input         AWVALID,
    output reg    AWREADY,
    
    //Write data
    input  [31:0] WDATA,
    input  [3:0]  WSTRB,
    input         WVALID,
    output reg    WREADY,
    
    //Write response
    output [1:0]  BRESP,
    output reg    BVALID,
    input         BREADY,
    
        
    output reg [31:0] control_reg,
    output reg        control_valid,
    input             control_read
    );
    
    assign ARREADY = 1'b0;
    assign RDATA   = 32'd0;
    assign RVALID  = 1'b0;
    assign RRESP   = 1'b0;
    assign BRESP   = 2'b00;
        
    integer i;
    
    always@(posedge ACLK or posedge ARESETN)begin
        if(ARESETN) begin
            control_reg <= 32'd0;
            AWREADY     <= 1'b1;
            WREADY      <= 1'b1;
        end else begin
            AWREADY     <= 1'b1;
            WREADY      <= 1'b1;
            if (WVALID) begin
                if (WSTRB[0]) control_reg[ 3: 0] <= WDATA[ 3: 0];
                if (WSTRB[1]) control_reg[ 7: 4] <= WDATA[ 7: 4];
                if (WSTRB[2]) control_reg[11: 8] <= WDATA[11: 8];
                if (WSTRB[3]) control_reg[15:12] <= WDATA[15:12];
                BVALID        <= 1'b1;
                control_valid <= 1'b1;
            end else begin
                if (BREADY) BVALID <= 1'b0;
                if (control_read) control_valid <= 1'b0;
            end
        end             
    end                    
            
        
            
endmodule
