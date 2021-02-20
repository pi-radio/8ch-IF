`timescale 1ns / 1ps
module tb;
	parameter integer C_S00_AXI_DATA_WIDTH	= 32;
    wire enable;
    reg aclk, aresetn;
    reg tready, tvalid, tlast;
    reg [C_S00_AXI_DATA_WIDTH-1:0] cntr;
    reg [C_S00_AXI_DATA_WIDTH-1:0] tdata_read_count;
    reg [C_S00_AXI_DATA_WIDTH-1:0] tdata_skip_count;
    initial begin
        aclk <= 1'b1;
        aresetn <= 1'b0;
        tready <= 1'b0;
        tvalid <= 1'b0;
        tlast <= 1'b0;
        tdata_read_count <= 32'h200;
        tdata_skip_count <= 32'h200;
        #50;
        aresetn <= 1'b1;
        #50;
        tready <= 1'b1;
        tvalid <= 1'b1;
        #40000;
        tlast <= 1'b1;
        #10;
        tlast <= 1'b0;
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
    
    axis_flow_ctrl #(
        .C_S00_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH)
    ) dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .tready(tready),
        .tvalid(tvalid),
        .enable(enable),
        .tlast(tlast),
        .tdata_read_count(tdata_read_count),
        .tdata_skip_count(tdata_skip_count)
    );
endmodule
