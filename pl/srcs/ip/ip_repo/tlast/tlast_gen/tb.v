`timescale 1ns / 1ps
module tb;
    reg aclk, aresetn;
    reg tready, tvalid;
    reg [31:0] cntr;
    wire enable;
    
    initial begin
        aclk <= 1'b1;
        aresetn <= 1'b0;
        tready <= 1'b0;
        tvalid <= 1'b0;
        #50;
        aresetn <= 1'b1;
        #50;
        tready <= 1'b1;
        tvalid <= 1'b1;
        #30000;
        $finish;
    end
    
    always @ (*) begin
        aclk <= #10 ~aclk;
    end
    
    always @ (posedge aclk) begin
        if (~aresetn)
            cntr <= 32'h0;
        else if (tready && tvalid && enable) begin
            cntr <= cntr+1'b1;
        end
    end
    wire [3:0] s00_axi_awaddr = 0;
    wire [2:0] s00_axi_awprot = 0;
    wire s00_axi_awvalid = 0;
    wire [31:0] s00_axi_wdata =0;
    wire [3:0] s00_axi_wstrb = 0;
    wire s00_axi_wvalid = 0;
    wire s00_axi_bready = 0;
    wire [3:0] s00_axi_araddr = 0;
    wire [2:0] s00_axi_arprot = 0;
    wire [2:0] s00_axi_arvalid = 0;
    wire s00_axi_rready = 0;
    
    tlast_gen_v1_0_0 dut (
        .axis_clk(aclk),
        .rstn(aresetn),
        .s00_axi_aclk(aclk),
        .s00_axi_aresetn(aresetn),
        .trdy(tready),
        .tvalid(tvalid),
        .adc_tready(tready),
        .adc_tvalid(tvalid),
        .enable(enable),
        .s00_axi_awaddr(s00_axi_awaddr),
        .s00_axi_awprot(s00_axi_awprot),
        .s00_axi_awvalid(s00_axi_awvalid),
        .s00_axi_wdata(s00_axi_wdata),
        .s00_axi_wstrb(s00_axi_wstrb),
        .s00_axi_wvalid(s00_axi_wvalid),
        .s00_axi_bready(s00_axi_bready),
        .s00_axi_araddr(s00_axi_araddr),
        .s00_axi_arprot(s00_axi_arprot),
        .s00_axi_arvalid(s00_axi_arvalid),
        .s00_axi_rready(s00_axi_rready)
    );
endmodule
