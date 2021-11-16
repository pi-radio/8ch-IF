`timescale 1ns / 1ps

module piradio_spi_ip_tb();

  integer i;
  reg aclk_reg, aresetn_reg, valid_reg;
  reg[3:0] awaddr_reg;
  reg[31:0] wdata_reg;
 
  spi_ip_v1 dut (
    .s_axi_aclk(aclk_reg),
    .s_axi_aresetn(aresetn_reg),
    .s_axi_awaddr(awaddr_reg),
    .s_axi_awvalid(valid_reg),
    .s_axi_wdata(wdata_reg),
    .s_axi_wvalid(valid_reg)
  );
 
  initial begin
    aclk_reg <= 1'b1;
    awaddr_reg <= 4'hF;
    valid_reg <= 1'b0;
    wdata_reg <= 32'hFFFFFFFF;
    aresetn_reg <= 1'b0;
    
    for(i=1; i<9000; i=i+1) begin
      #1;
      aclk_reg <= ~aclk_reg;
      
      if (i == 2) begin
        aresetn_reg <= 1'b0;
      end else if (i == 10) begin
        aresetn_reg <= 1'b1;
        awaddr_reg <= 4'h0;
        valid_reg <= 1'b1;
        wdata_reg <= 32'b0000_110110110110110110_000000_0000;  // Write 110110110110110110 to HMC_RX0
      end else if (i == 1010) begin
        aresetn_reg <= 1'b1;
        awaddr_reg <= 4'h0;
        valid_reg <= 1'b1;
        wdata_reg <= 32'b0000_110110110110110110_000000_0001;  // Write 110110110110110110 to HMC_RX1
      end else if (i == 2010) begin
        aresetn_reg <= 1'b1;
        awaddr_reg <= 4'h0;
        valid_reg <= 1'b1;
        wdata_reg <= 32'b0000_110110110110110110_000000_0010;  // Write 110110110110110110 to HMC_RX2
      end else if (i == 3010) begin
        aresetn_reg <= 1'b1;
        awaddr_reg <= 4'h0;
        valid_reg <= 1'b1;
        wdata_reg <= 32'b0000_110110110110110110_000000_0011;  // Write 110110110110110110 to HMC_RX3
      end else if (i == 4010) begin
        aresetn_reg <= 1'b1;
        awaddr_reg <= 4'h0;
        valid_reg <= 1'b1;
        wdata_reg <= 32'b0000_110110110110110110_000000_0100;  // Write 110110110110110110 to HMC_TX0
      end else if (i == 5010) begin
        aresetn_reg <= 1'b1;
        awaddr_reg <= 4'h0;
        valid_reg <= 1'b1;
        wdata_reg <= 32'b0000_110110110110110110_000000_0101;  // Write 110110110110110110 to HMC_TX1
      end else if (i == 6010) begin
        aresetn_reg <= 1'b1;
        awaddr_reg <= 4'h0;
        valid_reg <= 1'b1;
        wdata_reg <= 32'b0000_110110110110110110_000000_0110;  // Write 110110110110110110 to HMC_TX2
      end else if (i == 7010) begin
        aresetn_reg <= 1'b1;
        awaddr_reg <= 4'h0;
        valid_reg <= 1'b1;
        wdata_reg <= 32'b0000_110110110110110110_000000_0111;  // Write 110110110110110110 to HMC_TX3
      end else if (i == 8010) begin
        aresetn_reg <= 1'b1;
        awaddr_reg <= 4'h0;
        valid_reg <= 1'b1;
        wdata_reg <= 32'b0001_00001111_0011001100110011_1000;  // Write addr=00001111 data=0011001100110011 to the LMX
      end else begin
        awaddr_reg <= 4'hF;
        valid_reg <= 1'b0;
        wdata_reg <= 32'hFFFFFFFF;
      end
    end
  end
 
endmodule
