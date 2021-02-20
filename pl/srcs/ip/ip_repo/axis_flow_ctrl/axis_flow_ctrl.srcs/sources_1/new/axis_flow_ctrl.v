`timescale 1ns / 1ps
module axis_flow_ctrl #(
	parameter integer C_S00_AXI_DATA_WIDTH	= 32
)(
    input aclk,
    input aresetn,
    input tvalid,
    input tready,
    input tlast,
    input [C_S00_AXI_DATA_WIDTH-1:0] tdata_read_count,
    input [C_S00_AXI_DATA_WIDTH-1:0] tdata_skip_count,
    output reg enable
);
    
	reg  [C_S00_AXI_DATA_WIDTH-1:0] tdata_read_count_int = 32'h0000_0000;
		always @ (posedge aclk or negedge aresetn) begin
		if (!aresetn) begin
			tdata_read_count_int <= 32'h0000_0000;
		end
		else begin
			if (tlast || (tdata_read_count_int == (tdata_read_count + tdata_skip_count))) begin
				tdata_read_count_int <= 32'h0000_0000;
			end 
			else if (tvalid && tready) begin
				tdata_read_count_int <= tdata_read_count_int + 1'b1;
			end
			else begin 
				tdata_read_count_int <= tdata_read_count_int;
			end
		end
	end 
	always @ (posedge aclk) begin
		enable <= (tdata_read_count_int < (tdata_read_count - 1));
	end
	
endmodule
