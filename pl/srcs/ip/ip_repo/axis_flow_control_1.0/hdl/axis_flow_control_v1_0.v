
`timescale 1 ns / 1 ps

module axis_flow_control_v1_0 #(
	parameter integer C_S00_AXI_DATA_WIDTH	= 32,
	parameter integer C_S00_AXI_ADDR_WIDTH	= 4,
	parameter integer C_AXIS_DWIDTH = 512
) (
	input s00_axi_aclk,
	input s00_axi_aresetn,
	input [C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_awaddr,
	input [2:0] s00_axi_awprot,
	input s00_axi_awvalid,
	output s00_axi_awready,
	input [C_S00_AXI_DATA_WIDTH-1:0] s00_axi_wdata,
	input [(C_S00_AXI_DATA_WIDTH/8)-1:0] s00_axi_wstrb,
	input s00_axi_wvalid,
	output s00_axi_wready,
	output [1:0] s00_axi_bresp,
	output s00_axi_bvalid,
	input s00_axi_bready,
	input [C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_araddr,
	input [2:0] s00_axi_arprot,
	input s00_axi_arvalid,
	output s00_axi_arready,
	output [C_S00_AXI_DATA_WIDTH-1:0] s00_axi_rdata,
	output [1:0] s00_axi_rresp,
	output s00_axi_rvalid,
	input s00_axi_rready,
	
	input axis_aclk,
	input axis_aresetn,
	
	input s_axis_tvalid,
	input [C_AXIS_DWIDTH-1:0] s_axis_tdata,
	output s_axis_tready,
	
	output m_axis_tvalid,
	output [C_AXIS_DWIDTH-1:0] m_axis_tdata,
	input m_axis_tready,
	
	input tlast
);
	wire [31:0] tdata_read_count;
	wire [31:0] tdata_pause_count;
	// Instantiation of Axi Bus Interface S00_AXI
	axis_flow_control_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) axis_flow_control_v1_0_S00_AXI_inst (
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready),
		.read_max(tdata_read_count),
		.skip_max(tdata_pause_count)
	);
	reg [31:0] cntr;
	assign s_axis_tready = m_axis_tready;
	assign m_axis_tdata = s_axis_tdata;
	assign m_axis_tvalid = s_axis_tvalid && ((cntr < tdata_read_count) || (tdata_read_count == 32'h0000_0000));
	
	always @ (posedge axis_aclk) begin
		if (~axis_aresetn) begin
			cntr <= 32'h0000_0000;		
		end
		else begin
			if (tlast || (cntr == (tdata_read_count + tdata_pause_count))) begin
				cntr <= 32'h0000_0000;		
			end
			else if (s_axis_tvalid && m_axis_tready) begin
				cntr <= cntr + 32'h0000_00001;
			end
			else begin
			 cntr <= cntr;
			end
		end
	end
endmodule
