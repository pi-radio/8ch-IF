
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
    input   wire  spi_hmc630x_miso,
    output  wire  spi_rx0_senb,
    output  wire  spi_rx1_senb,
    output  wire  spi_rx2_senb,
    output  wire  spi_rx3_senb,
    output  wire  spi_rx4_senb,
    output  wire  spi_rx5_senb,
    output  wire  spi_rx6_senb,
    output  wire  spi_rx7_senb,
    
    output  wire  spi_tx0_senb,
    output  wire  spi_tx1_senb,
    output  wire  spi_tx2_senb,
    output  wire  spi_tx3_senb,
    output  wire  spi_tx4_senb,
    output  wire  spi_tx5_senb,
    output  wire  spi_tx6_senb,
    output  wire  spi_tx7_senb,
    
    output  wire  spi_ltc0_senb,
    output  wire  spi_ltc1_senb,
    output  wire  spi_ltc2_senb,
    output  wire  spi_ltc3_senb,
    output  wire  spi_ltc4_senb,
    output  wire  spi_ltc5_senb,
    output  wire  spi_ltc6_senb,
    output  wire  spi_ltc7_senb,
        
    output  wire  spi_lmx_senb,
    output  wire  spi_axi_error,
    output  wire  obs_ctrl_wire,
    output  wire [7:0] led_wire,

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
		.S_AXI_RDATA(), // We will "hijack" s_axi_rdata
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
  reg obs_ctrl_reg;
  reg[7:0] led_reg;
  reg[3:0] chip_type_reg;

  // These are outputs from program_one_reg
  wire SENb_wire;
  wire done_wire;
  
  // Wires to swap MOSI and SCLK because of a small bug on the v3 board.
  // The bug has been fixed on Hedy Lamarr. But these wires are still used.
  wire spi_mosi_wire;
  wire spi_clk_wire;

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
      // Have we received an AXI Read request?
      if (s_axi_rvalid == 1'b1 && s_axi_arvalid == 1'b1) begin
        
      end
      if (s_axi_wvalid == 1'b1 && s_axi_awvalid == 1'b1) begin
        // We have received an AXI command
        if (s_axi_awaddr == 4'h0) begin
          // We have received an SPI read/write command
          if (active_reg == 1'b1) begin
            // This is bad. We have received an SPI read/write command too early
            spi_axi_error_reg <= 1'b1;
          end else begin
            // We have received an SPI read/write commend, and we should service it
            active_reg <= 1'b1;
            release_por_reset <= 1'b1; // release in the next clock
            chip_index_reg <= s_axi_wdata[3:0];
            chip_type_reg <= s_axi_wdata[31:28];
            
            if (s_axi_wdata[31:28] == 4'd0) begin
              // This is an ADI HMC 6300 chip: Write
              rd_req_reg <= 1'b0;
              addr_reg <= s_axi_wdata[27:10];
              wr_data_reg <= 16'd0;
              addr_width_m1_reg <= 5'd17;
              data_width_m1_reg <= 5'd0;
              chip_type_reg <= 4'd0;
            end else if (s_axi_wdata[31:28] == 4'd1) begin
              // This is an ADI HMC6301 chip: Write
              rd_req_reg <= 1'b0;
              addr_reg <= s_axi_wdata[27:10];
              wr_data_reg <= 16'd0;
              addr_width_m1_reg <= 5'd17;
              data_width_m1_reg <= 5'd0;
              chip_type_reg <= 4'd1;
            end else if (s_axi_wdata[31:28] == 4'd2) begin
              // This is a TI LMX chip: Write
              rd_req_reg <= 1'b0;
              addr_reg <= s_axi_wdata[27:20];
              wr_data_reg <= s_axi_wdata[19:4];
              addr_width_m1_reg <= 5'd7;
              data_width_m1_reg <= 5'd15;
              chip_type_reg <= 4'd2;              
            end else if (s_axi_wdata[31:28] == 4'd3) begin
              // This is a LTC5586 or LTC5594 chip: Write
              rd_req_reg <= 1'b0;
              addr_reg <= s_axi_wdata[27:20];
              wr_data_reg <= s_axi_wdata[19:12];
              addr_width_m1_reg <= 5'd7;
              data_width_m1_reg <= 5'd7;
              chip_type_reg <= 4'd3;              
            end else if (s_axi_wdata[31:28] == 4'd8) begin
              // This is an ADI HMC 6300 chip: Read - DOES NOT WORK
              rd_req_reg <= 1'b1;
              addr_reg <= s_axi_wdata[27:10];
              wr_data_reg <= 16'd0;
              addr_width_m1_reg <= 5'd17;
              data_width_m1_reg <= 5'd0;
              chip_type_reg <= 4'd0;
            end else if (s_axi_wdata[31:28] == 4'd9) begin
              // This is an ADI HMC 6301 chip: Read - DOES NOT WORK
              rd_req_reg <= 1'b1;
              addr_reg <= s_axi_wdata[27:10];
              wr_data_reg <= 16'd0;
              addr_width_m1_reg <= 5'd17;
              data_width_m1_reg <= 5'd0;
              chip_type_reg <= 4'd1;
            end else if (s_axi_wdata[31:28] == 4'd14) begin
              // This is a control command for the OBS Ctrl
              obs_ctrl_reg <= s_axi_wdata[0:0];
            end else if (s_axi_wdata[31:28] == 4'd15) begin
              // This is to control the LEDs on the RFSoC (PL side)
              led_reg <= s_axi_wdata[7:0];
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

  assign spi_rx0_senb = ((chip_type_reg == 4'd1) && (chip_index_reg == 4'd0)) ? SENb_wire : 1'b1;
  assign spi_rx1_senb = ((chip_type_reg == 4'd1) && (chip_index_reg == 4'd1)) ? SENb_wire : 1'b1;
  assign spi_rx2_senb = ((chip_type_reg == 4'd1) && (chip_index_reg == 4'd2)) ? SENb_wire : 1'b1;
  assign spi_rx3_senb = ((chip_type_reg == 4'd1) && (chip_index_reg == 4'd3)) ? SENb_wire : 1'b1;
  assign spi_rx4_senb = ((chip_type_reg == 4'd1) && (chip_index_reg == 4'd4)) ? SENb_wire : 1'b1;
  assign spi_rx5_senb = ((chip_type_reg == 4'd1) && (chip_index_reg == 4'd5)) ? SENb_wire : 1'b1;
  assign spi_rx6_senb = ((chip_type_reg == 4'd1) && (chip_index_reg == 4'd6)) ? SENb_wire : 1'b1;
  assign spi_rx7_senb = ((chip_type_reg == 4'd1) && (chip_index_reg == 4'd7)) ? SENb_wire : 1'b1;
    
  assign spi_tx0_senb = ((chip_type_reg == 4'd0) && (chip_index_reg == 4'd0)) ? SENb_wire : 1'b1;
  assign spi_tx1_senb = ((chip_type_reg == 4'd0) && (chip_index_reg == 4'd1)) ? SENb_wire : 1'b1;
  assign spi_tx2_senb = ((chip_type_reg == 4'd0) && (chip_index_reg == 4'd2)) ? SENb_wire : 1'b1;
  assign spi_tx3_senb = ((chip_type_reg == 4'd0) && (chip_index_reg == 4'd3)) ? SENb_wire : 1'b1;
  assign spi_tx4_senb = ((chip_type_reg == 4'd0) && (chip_index_reg == 4'd4)) ? SENb_wire : 1'b1;
  assign spi_tx5_senb = ((chip_type_reg == 4'd0) && (chip_index_reg == 4'd5)) ? SENb_wire : 1'b1;
  assign spi_tx6_senb = ((chip_type_reg == 4'd0) && (chip_index_reg == 4'd6)) ? SENb_wire : 1'b1;
  assign spi_tx7_senb = ((chip_type_reg == 4'd0) && (chip_index_reg == 4'd7)) ? SENb_wire : 1'b1;
  
  assign spi_ltc0_senb = ((chip_type_reg == 4'd3) && (chip_index_reg == 4'd0)) ? SENb_wire : 1'b1;
  assign spi_ltc1_senb = ((chip_type_reg == 4'd3) && (chip_index_reg == 4'd1)) ? SENb_wire : 1'b1;
  assign spi_ltc2_senb = ((chip_type_reg == 4'd3) && (chip_index_reg == 4'd2)) ? SENb_wire : 1'b1;
  assign spi_ltc3_senb = ((chip_type_reg == 4'd3) && (chip_index_reg == 4'd3)) ? SENb_wire : 1'b1;
  assign spi_ltc4_senb = ((chip_type_reg == 4'd3) && (chip_index_reg == 4'd4)) ? SENb_wire : 1'b1;
  assign spi_ltc5_senb = ((chip_type_reg == 4'd3) && (chip_index_reg == 4'd5)) ? SENb_wire : 1'b1;
  assign spi_ltc6_senb = ((chip_type_reg == 4'd3) && (chip_index_reg == 4'd6)) ? SENb_wire : 1'b1;
  assign spi_ltc7_senb = ((chip_type_reg == 4'd3) && (chip_index_reg == 4'd7)) ? SENb_wire : 1'b1;
    
  // This bug doesn't exist on the v3 - Hedy lamarr
  // Fix the bug on the v3 board. If HMC, swap the mosi and clk lines
  // assign spi_mosi = (chip_type_reg == 4'd2) ? spi_mosi_wire : spi_clk_wire; 
  // assign spi_clk  = (chip_type_reg == 4'd2) ? spi_clk_wire  : spi_mosi_wire;
  assign spi_mosi = spi_mosi_wire;
  assign spi_clk  = spi_clk_wire;
  
  // There is only one LMX chip on the board
  assign spi_lmx_senb = ((chip_type_reg == 4'd2) && (chip_index_reg == 4'd0)) ? SENb_wire : 1'b1;
   
  assign obs_ctrl_wire = obs_ctrl_reg;
  assign led_wire = led_reg;

  program_one_reg program_one_reg_i0 (
    .reset(por_reset_reg),
    .clk(s_axi_aclk),
    .SDI(spi_miso),
    .SDO(spi_mosi_wire),
    .SENb(SENb_wire),
    .SCLK(spi_clk_wire),
    .oe(),
    .rd_data_wire(s_axi_rdata),
    .addr(addr_reg),
    .wr_data(wr_data_reg),
    .done(done_wire),
    .rd_req(rd_req_reg),
    .addr_width_m1(addr_width_m1_reg),
    .data_width_m1(data_width_m1_reg)
  );

	// User logic ends

	endmodule
