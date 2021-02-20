
`timescale 1 ns / 1 ps

module tlast_gen_v1_0 #(
	parameter integer C_S00_AXI_DATA_WIDTH	= 32,
	parameter integer C_S00_AXI_ADDR_WIDTH	= 4,
	parameter integer C_AXIS_DATA_WIDTH = 512
) (
	// Users to add ports here
	input trdy,
	input tvalid,
	input axis_clk,
	output reg tlast = 1'b0,
	
	input rstn,
	output [C_S00_AXI_DATA_WIDTH-1:0] tdata_read_count,
	output [C_S00_AXI_DATA_WIDTH-1:0] tdata_skip_count,
	
	// Ports of Axi Slave Bus Interface S00_AXI
	input s00_axi_aclk,
	input s00_axi_aresetn,
	input [C_S00_AXI_ADDR_WIDTH-1 : 0]	s00_axi_awaddr,
	input [2 : 0] s00_axi_awprot,
	input s00_axi_awvalid,
	output s00_axi_awready,
	input [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
	input [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
	input s00_axi_wvalid,
	output s00_axi_wready,
	output [1 : 0] s00_axi_bresp,
	output s00_axi_bvalid,
	input s00_axi_bready,
	input [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
	input [2 : 0] s00_axi_arprot,
	input s00_axi_arvalid,
	output s00_axi_arready,
	output [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
	output [1 : 0] s00_axi_rresp,
	output s00_axi_rvalid,
	input s00_axi_rready
);
	// Add user logic here
	wire [C_S00_AXI_DATA_WIDTH-1:0] tdata_byte_count;
	reg  [C_S00_AXI_DATA_WIDTH-1:0] tdata_byte_count_int = 32'h0000_0000;
	
	// Instantiation of Axi Bus Interface S00_AXI
	tlast_gen_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) tlast_gen_v1_0_S00_AXI_inst (
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
		.tdata_byte_count(tdata_byte_count),
		.tdata_byte_count_int(tdata_byte_count_int),
		.tdata_read_count(tdata_read_count),
		.tdata_pause_count(tdata_skip_count)
	);

	reg tlast_int = 1'b0;
	
	always @ (posedge axis_clk or negedge rstn) begin
		// reset the counter with every tlast 
		if (!rstn) begin
			tdata_byte_count_int <= 32'h0000_0000;
//			tdata_read_count_int <= 32'h0000_0000;
		end
		else begin 
			if (tvalid && trdy && tlast) begin
				tdata_byte_count_int <= 32'h0000_0000;
			end 
			// Increment the count with every Beat
			else if (tvalid && trdy) begin
				tdata_byte_count_int <= tdata_byte_count_int + (C_AXIS_DATA_WIDTH>>3);
			end
			else begin 
				tdata_byte_count_int <= tdata_byte_count_int;
			end
		end
	end 

	always @ (posedge axis_clk) begin
		// reset the counter with every tlast 
		if (tvalid && trdy && tlast) begin
			tlast <= 1'b0;  
		end
		else if (tvalid && trdy && ((tdata_byte_count-(C_AXIS_DATA_WIDTH>>2)) == tdata_byte_count_int)) begin
			tlast <= 1'b1;
		end
		else begin 
			tlast <= tlast;
		end
	end
endmodule
