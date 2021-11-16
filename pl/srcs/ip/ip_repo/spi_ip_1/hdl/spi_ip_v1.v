
`timescale 1 ns / 1 ps

	module spi_ip_v1 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S_AXI
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here
		output  wire  spi_clk,
    output  wire  spi_mosi,
    input   wire  spi_miso,
    output  wire  spi_rx0_senb,
    output  wire  spi_rx1_senb,
    output  wire  spi_rx2_senb,
    output  wire  spi_rx3_senb,
    output  wire  spi_tx0_senb,
    output  wire  spi_tx1_senb,
    output  wire  spi_tx2_senb,
    output  wire  spi_tx3_senb,
    output  wire  spi_lmx_senb,
    output  wire  spi_axi_error,

		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S_AXI
		input wire  s_axi_aclk,
		input wire  s_axi_aresetn,
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_awaddr,
		input wire [2 : 0] s_axi_awprot,
		input wire  s_axi_awvalid,
		output wire  s_axi_awready,
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_wdata,
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb,
		input wire  s_axi_wvalid,
		output wire  s_axi_wready,
		output wire [1 : 0] s_axi_bresp,
		output wire  s_axi_bvalid,
		input wire  s_axi_bready,
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_araddr,
		input wire [2 : 0] s_axi_arprot,
		input wire  s_axi_arvalid,
		output wire  s_axi_arready,
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_rdata,
		output wire [1 : 0] s_axi_rresp,
		output wire  s_axi_rvalid,
		input wire  s_axi_rready
	);
// Instantiation of Axi Bus Interface S_AXI
	spi_ip_v1_S_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	) spi_ip_v1_S_AXI_inst (
		.S_AXI_ACLK(s_axi_aclk),
		.S_AXI_ARESETN(s_axi_aresetn),
		.S_AXI_AWADDR(s_axi_awaddr),
		.S_AXI_AWPROT(s_axi_awprot),
		.S_AXI_AWVALID(s_axi_awvalid),
		.S_AXI_AWREADY(s_axi_awready),
		.S_AXI_WDATA(s_axi_wdata),
		.S_AXI_WSTRB(s_axi_wstrb),
		.S_AXI_WVALID(s_axi_wvalid),
		.S_AXI_WREADY(s_axi_wready),
		.S_AXI_BRESP(s_axi_bresp),
		.S_AXI_BVALID(s_axi_bvalid),
		.S_AXI_BREADY(s_axi_bready),
		.S_AXI_ARADDR(s_axi_araddr),
		.S_AXI_ARPROT(s_axi_arprot),
		.S_AXI_ARVALID(s_axi_arvalid),
		.S_AXI_ARREADY(s_axi_arready),
		.S_AXI_RDATA(s_axi_rdata),
		.S_AXI_RRESP(s_axi_rresp),
		.S_AXI_RVALID(s_axi_rvalid),
		.S_AXI_RREADY(s_axi_rready)
	);

	// Add user logic here
	// These are inputs into program_one_reg
  reg reset_reg;
  reg[17:0] addr_reg;
  reg[15:0] wr_data_reg;
  reg[4:0] addr_width_m1_reg;
  reg[4:0] data_width_m1_reg;
  reg rd_req_reg;
  reg por_reset_reg, release_por_reset;
  reg[3:0] chip_index_reg;

  // These are outputs from program_one_reg
  wire SENb_wire;
  wire done_wire;

  // These registers are to maintain state at the top level (here)
  reg active_reg, spi_axi_error_reg;

  assign spi_axi_error = spi_axi_error_reg;

  always @(posedge s_axi_aclk) begin
    if (s_axi_aresetn == 1'b0) begin
      active_reg <= 1'b0;
      spi_axi_error_reg <= 1'b0;
      por_reset_reg <= 1'b1; // Active HIGH reset
      release_por_reset <= 1'b0;
    end else begin
      if (s_axi_wvalid == 1'b1 && s_axi_awvalid == 1'b1) begin
        // We have received an AXI command
        if (s_axi_awaddr == 4'h0) begin
          // We have received an SPI write command
          rd_req_reg <= 1'b0;
          if (active_reg == 1'b1) begin
            // This is bad. We have received an SPI write command too early
            spi_axi_error_reg <= 1'b1;
          end else begin
            // We have received an SPI write commend, and we should service it
            active_reg <= 1'b1;
            release_por_reset <= 1'b1; // release in the next clock
            chip_index_reg <= s_axi_wdata[3:0];
            if (s_axi_wdata[31:28] == 4'b0000) begin
              // This is an ADI HMC chip
              addr_reg <= s_axi_wdata[27:10];
              wr_data_reg <= 16'd0;
              addr_width_m1_reg <= 5'd17;
              data_width_m1_reg <= 5'd0;
            end else if (s_axi_wdata[31:28] == 4'b0001) begin
              // This is a TI LMX chip
              addr_reg <= s_axi_wdata[27:20];
              wr_data_reg <= s_axi_wdata[19:4];
              addr_width_m1_reg <= 5'd7;
              data_width_m1_reg <= 5'd15;
            end else begin
              // This is an error. Reserved for future use
              spi_axi_error_reg <= 1'b1;
            end
          end
        end
      end else begin
        // NOT of (s_axi_wvalid == 1'b1 && s_axi_awvalid == 1'b1)
        if (done_wire == 1'b1) begin
          active_reg <= 1'b0;
          por_reset_reg <= 1'b1;
        end else if (release_por_reset == 1'b1) begin
          por_reset_reg <= 1'b0;
          release_por_reset <= 1'b0;
        end else begin
          // Do nothing
        end
      end
    end
  end

  assign spi_rx0_senb = chip_index_reg == 4'd0 ? SENb_wire : 1'b1;
  assign spi_rx1_senb = chip_index_reg == 4'd1 ? SENb_wire : 1'b1;
  assign spi_rx2_senb = chip_index_reg == 4'd2 ? SENb_wire : 1'b1;
  assign spi_rx3_senb = chip_index_reg == 4'd3 ? SENb_wire : 1'b1;
  assign spi_tx0_senb = chip_index_reg == 4'd4 ? SENb_wire : 1'b1;
  assign spi_tx1_senb = chip_index_reg == 4'd5 ? SENb_wire : 1'b1;
  assign spi_tx2_senb = chip_index_reg == 4'd6 ? SENb_wire : 1'b1;
  assign spi_tx3_senb = chip_index_reg == 4'd7 ? SENb_wire : 1'b1;
  assign spi_lmx_senb = chip_index_reg == 4'd8 ? SENb_wire : 1'b1;

  program_one_reg program_one_reg_i0 (
    .reset(por_reset_reg),
    .clk(s_axi_aclk),
    .SDI(spi_miso),
    .SDO(spi_mosi),
    .SENb(SENb_wire),
    .SCLK(spi_clk),
    .oe(),
    .rd_data_wire(),
    .addr(addr_reg),
    .wr_data(wr_data_reg),
    .done(done_wire),
    .rd_req(rd_req_reg),
    .addr_width_m1(addr_width_m1_reg),
    .data_width_m1(data_width_m1_reg)
  );

	// User logic ends

	endmodule
