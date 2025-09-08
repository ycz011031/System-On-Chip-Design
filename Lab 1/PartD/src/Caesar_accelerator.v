`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/07/2025 05:08:24 PM
// Design Name: 
// Module Name: Caesar_accelerator
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


module Caesar_accelerator(
    input wire      aclk,
    input wire      aresetn,

  // AXIS Slave (input chars -> accelerator)
    input wire [31:0]   s_axis_tdata,
    input wire [3:0]    s_axis_tkeep,
    input wire          s_axis_tvalid,
    output wire         s_axis_tready,
    input  wire         s_axis_tlast,
    
    // AXIS Master (output shifted chars)
    output reg  [31:0]  m_axis_tdata,
    output reg  [3:0]   m_axis_tkeep,
    output reg          m_axis_tvalid,
    input wire          m_axis_tready,
    output reg          m_axis_tlast,
    
    // AXI-Lite Slave
    input  wire         s_axi_awvalid,
    output wire         s_axi_awready,
    input  wire [31:0]  s_axi_awaddr,
    
    input  wire         s_axi_wvalid,
    output wire         s_axi_wready,
    input  wire [31:0]  s_axi_wdata,
    input  wire [3:0]   s_axi_wstrb,
    
    output wire         s_axi_bvalid,
    input  wire         s_axi_bready,
    output wire  [1:0]  s_axi_bresp,
    
    input  wire         s_axi_arvalid,
    output wire         s_axi_arready,
    input  wire [31:0]  s_axi_araddr,
    
    output wire         s_axi_rvalid,
    input  wire         s_axi_rready,
    output wire  [31:0] s_axi_rdata,
    output wire  [1:0]  s_axi_rresp
);


    //Shift amount, configured through AXIL
    reg  signed [31:0]  shift_k;
    
    wire signed [31:0]  shift_data;
    wire                shift_valid;
    
    // shift k update logic
    always @(posedge aclk or negedge aresetn)begin
        if(~aresetn) begin
            shift_k     <= 32'b0;
        end else begin
            if (shift_valid) begin
                shift_k <= shift_data;
            end
        end
    end    
    
    function [7:0] shift_char;
        input [7:0] c;                // one ASCII byte
        input signed [31:0] n;         // normalized shift in [-25..+25]
        reg [7:0] base, off;
        begin
            if (c >= "A" && c <= "Z") begin
                base = "A"; off = c - base;
                shift_char = base + ((off + n % 26 + 26) % 26);
            end else if (c >= "a" && c <= "z") begin
                base = "a"; off = c - base;
                shift_char = base + ((off + n % 26 + 26) % 26);
            end else begin
                shift_char = c; // digits, punctuation, space are unchanged
            end
        end
    endfunction
    
    //backpressure
    assign s_axis_tready = m_axis_tready || !m_axis_tvalid;
    
    //AXI stream interaction
    always @(posedge aclk or negedge aresetn)begin
        if(~aresetn) begin
            m_axis_tdata  <= 32'd0;
            m_axis_tkeep  <= 4'b0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;
        end else begin
            m_axis_tdata[7:0]    <= shift_char(s_axis_tdata[7:0],    shift_k);
            m_axis_tdata[15:8]   <= shift_char(s_axis_tdata[15:8],   shift_k);
            m_axis_tdata[23:16]  <= shift_char(s_axis_tdata[23:16],  shift_k);
            m_axis_tdata[31:24]  <= shift_char(s_axis_tdata[31:24],  shift_k);
            m_axis_tkeep  <= s_axis_tkeep;
            m_axis_tvalid <= s_axis_tvalid;
            m_axis_tlast  <= s_axis_tlast;
        end
    end            

    Caesar_AXIL_S AXIL(
        .aclk          (aclk),
        .aresetn       (aresetn),
    
        .s_axi_awvalid (s_axi_awvalid),
        .s_axi_awready (s_axi_awready),
        .s_axi_awaddr  (s_axi_awaddr),
    
        .s_axi_wvalid  (s_axi_wvalid),
        .s_axi_wready  (s_axi_wready),
        .s_axi_wdata   (s_axi_wdata),
        .s_axi_wstrb   (s_axi_wstrb),
    
        .s_axi_bvalid  (s_axi_bvalid),
        .s_axi_bready  (s_axi_bready),
        .s_axi_bresp   (s_axi_bresp),
    
        .s_axi_arvalid (s_axi_arvalid),
        .s_axi_arready (s_axi_arready),
        .s_axi_araddr  (s_axi_araddr),
    
        .s_axi_rvalid  (s_axi_rvalid),
        .s_axi_rready  (s_axi_rready),
        .s_axi_rdata   (s_axi_rdata),
        .s_axi_rresp   (s_axi_rresp),
    
        .shift_data    (shift_data),
        .shift_valid   (shift_valid)
        );
    
    
endmodule
