`timescale 1ns / 1ps

module piradio_spi_ip_tb();

  integer i;
  reg aclk_reg, aresetn_reg, spi_miso_reg;
  reg wvalid_reg, rvalid_reg, rready_reg;
  reg[3:0] awaddr_reg;
  reg[3:0] araddr_reg;
  reg[31:0] wdata_reg;
 
  spi_ip_v1 dut (
    .s_axi_aclk(aclk_reg),
    .s_axi_aresetn(aresetn_reg),
    
    .s_axi_awaddr(awaddr_reg),
    .s_axi_awvalid(wvalid_reg),
    .s_axi_wdata(wdata_reg),
    .s_axi_wvalid(wvalid_reg),
    
    .s_axi_araddr(araddr_reg),
    .s_axi_arvalid(rvalid_reg),
    .s_axi_rready(rready_reg),
    
    .spi_miso(spi_miso_reg)
  );
 
  initial begin
    aclk_reg <= 1'b1;
    awaddr_reg <= 4'hF;
    wvalid_reg <= 1'b0;
    rvalid_reg <= 1'b0;
    rready_reg <= 1'b0;
    wdata_reg <= 32'hFFFFFFFF;
    aresetn_reg <= 1'b0;
    
    spi_miso_reg <= 1'b1;
    
    for(i=1; i<9000; i=i+1) begin
      #1;
      aclk_reg <= ~aclk_reg;
      
      if (i == 2) begin
        aresetn_reg <= 1'b0;
      end else if (i == 10) begin
        // Issue command to Write register to HMC
        aresetn_reg <= 1'b1;
        awaddr_reg <= 4'h0;
        wvalid_reg <= 1'b1;
        wdata_reg <= 32'h0_00_82_c0_4;
//      end else if (i == 1010) begin
//        // Issue local register read to retrieve the value
//        araddr_reg <= 4'h0;
//        rvalid_reg <= 1'b1;
//        rready_reg <= 1'b1;
      end else begin
        awaddr_reg <= 4'hF;
        araddr_reg <= 4'hF;
        wvalid_reg <= 1'b0;
        rvalid_reg <= 1'b0;
        rready_reg <= 1'b1;
        wdata_reg <= 32'hFFFFFFFF;
      end
    end
  end
 
endmodule
