`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  Pi-Radio Inc
// Engineer:  Aditya Dhananjay
// Module Name: program_one_reg
//
// The goal of this module is to write a register value and read the same value
// back! Just for one register on one chip! This will be used as a "sub" within
// a larger design.
//////////////////////////////////////////////////////////////////////////////////

module program_one_reg(
  input  wire reset,
  input  wire clk,
  input  wire SDI,      // Input wire
  output wire SDO,      // Output wire
  output wire SENb,     // Active low chip-enable
  output wire SCLK,
  output wire oe,       // OP Valid (If true, SDIO is output. Else, SDIO is input)
  output wire[15:0]  rd_data_wire,
  input  wire[17:0] addr,
  input  wire[15:0]  wr_data,
  output wire done,
  input  wire rd_req,
  input  wire[4:0] addr_width_m1,   // Can take values up to 31 (represented as a minus one)
  input  wire[4:0] data_width_m1    // Can take values up to 31 (represented as a minus one) 
);

localparam state_wrreg_wraddr = 4'd0; // Write register: write the address
localparam state_wrreg_wrdata = 4'd1; // Write register: write the data
localparam state_wait_onetick = 4'd2; // Make sure that the read/write is complete
localparam state_rdreg_wraddr = 4'd3; // Read register: write the address to read
localparam state_burn_tick    = 4'd4; // Start reading on the next tick
localparam state_rdreg_rddata = 4'd5; // Read register: read the data
localparam state_done         = 4'd6; // We are done.
localparam state_adi_rw_wait  = 4'd7; // Pull up SENb and then pull it down again

reg[15:0]   rd_data;
reg[5:0]    clock_state;
reg         SCLK_reg;
reg         SENb_reg;
reg[3:0]    state;
reg[4:0]    bit_index;    // Used for addr and data
reg         SDO_reg;
reg[3:0]    wait_count;
reg         oe_reg;
reg[2:0]    ticks_to_wait_after_reset;
reg[2:0]    rw_wait_count;

assign SCLK = SCLK_reg;
assign SENb = SENb_reg;
assign SDO = SDO_reg;
assign oe = oe_reg;
assign rd_data_wire[15] = rd_data[15];
assign rd_data_wire[14] = rd_data[14];
assign rd_data_wire[13] = rd_data[13];
assign rd_data_wire[12] = rd_data[12];
assign rd_data_wire[11] = rd_data[11];
assign rd_data_wire[10] = rd_data[10];
assign rd_data_wire[9] = rd_data[9];
assign rd_data_wire[8] = rd_data[8];
assign rd_data_wire[7] = rd_data[7];
assign rd_data_wire[6] = rd_data[6];
assign rd_data_wire[5] = rd_data[5];
assign rd_data_wire[4] = rd_data[4];
assign rd_data_wire[3] = rd_data[3];
assign rd_data_wire[2] = rd_data[2];
assign rd_data_wire[1] = rd_data[1];
assign rd_data_wire[0] = rd_data[0];
assign done = (state == state_done)? 1'b1 : 1'b0;


always @(posedge clk) begin
  if (reset == 1'b1) begin
    // Reset things
    clock_state <= 6'd0;
    SENb_reg <= 1'b1;
    SCLK_reg <= 1'b0;
    
    if (rd_req == 1'b1) begin
      state <= state_rdreg_wraddr;
    end else begin
      state <= state_wrreg_wraddr;
    end
      
    bit_index <= addr_width_m1; // Was 4'd15;
    //rd_data <= 16'h00;          // Up to 16 bits. 8 or 16 bits are used
    SDO_reg <= 1'b0;
    wait_count <= 4'd0;
    oe_reg <= 1'b1;
    ticks_to_wait_after_reset <= ~(3'b0);
  end else if (ticks_to_wait_after_reset > 0) begin
    ticks_to_wait_after_reset <= ticks_to_wait_after_reset - 1;
    if (rd_req == 1'b1) begin
      state <= state_rdreg_wraddr;
    end else begin
      state <= state_wrreg_wraddr;
    end
  end else if (state == state_done) begin
    // Do nothing. We are done.
    SDO_reg <= 1'b0;
    SCLK_reg <= 1'b0;
    SENb_reg <= 1'b1;
    clock_state <= 6'd0;
  end else begin
    clock_state <= clock_state + 1;
    
    case(clock_state)
    
      6'd0: begin
        case (state)
          state_wrreg_wraddr: begin
            SENb_reg <= 1'b0;
            SDO_reg <= addr[bit_index];
            if (bit_index == 5'd0) begin
              if (addr_width_m1 == 5'd17) begin // This is an ADI chip
                state <= state_wait_onetick;
              end else begin
                bit_index <= data_width_m1; // Was 4'd7;
                state <= state_wrreg_wrdata;
              end 
            end else begin
              bit_index <= bit_index - 1;
            end
          end
              
          state_wrreg_wrdata: begin
            SENb_reg <= 1'b0;
            SDO_reg <= wr_data[bit_index];
            if (bit_index == 5'd0) begin
              bit_index <= addr_width_m1; // Was 4'd15;
              state <= state_wait_onetick;
              wait_count <= 4'd4;                         
            end else begin
              bit_index <= bit_index - 1;
            end
          end
              
          state_rdreg_wraddr: begin
            SENb_reg <= 1'b0;
            rd_data <= 16'h0;
            
            if ((bit_index == addr_width_m1) && (addr_width_m1 != 5'd17)) // Write the first bit as 1 only for TI chips
              SDO_reg <= 1'b1;
            else
              SDO_reg <= addr[bit_index];
            
            if (bit_index == 5'd0) begin
              bit_index <= data_width_m1; // Was 4'd7;
              // Burn the rest of this tick (where the address is written)
              // Start reading on the falling edge of the next tick. Not of this tick.
              if (addr_width_m1 == 5'd17) begin     // This is an ADI chip
                rw_wait_count <= 3'd1;
                state <= state_adi_rw_wait;
              end else begin                        // This is a TI chip
                state <= state_burn_tick;
              end
            end else begin
              bit_index <= bit_index - 1;
            end
          end
              
          default: begin
            // Do nothing in any other state
          end
              
        endcase // state
      end // clock_state == 4'd0
      
      6'd8: begin
        // Keep SDO_reg unchanged to meet the hold requirement.
        SCLK_reg <= 1'b1;
        case (state)
          state_rdreg_rddata: begin
            rd_data[bit_index] <= SDI;
            if (bit_index == 5'd0) begin
              bit_index <= addr_width_m1; // Was 4'd15;
              state <= state_wait_onetick;
            end else begin
              bit_index <= bit_index - 1;
            end
          end
        endcase
      end // clock_state == 6'd8
      
      6'd16: begin
        SDO_reg <= 1'b0;
      end // clock_state == 6'd16
      
      6'd24: begin
      end // clock_state == 6'd24
      
      6'd32: begin
      end // clock_state == 6'd32
      
      6'd40: begin
        // Trigger the negative edge of the clock
        SCLK_reg <= 1'b0;
      end // clock_state == 6'd40
      
      6'd48: begin
        case (state)
          state_wait_onetick: begin
            state <= state_done;
          end
          state_burn_tick: begin
            state <= state_rdreg_rddata;
          end
          state_adi_rw_wait: begin
            rw_wait_count <= rw_wait_count - 3'd1;
            if (rw_wait_count == 3'd0) begin
                SENb_reg <= 1'b0;   // Pull SENb back down low
                state <= state_rdreg_rddata;
                bit_index <= 5'd7; // We will need to read 8 bits now
            end else begin
                SENb_reg <= 1'b1;   // Pull SENb high temporarily
            end
          end
        endcase
      end // clock_state == 6'd48
      
      6'd56: begin
      end // clock_state == 6'd56
      
      6'd4: begin
      end // clock_state == 6'd4
      
      6'd12: begin
      end // clock_state == 6'd12
      
      6'd20: begin
      end // clock_state == 6'd20
      
      6'd28: begin
      end // clock_state == 6'd28
      
      6'd36: begin
      end // clock_state == 6'd36
      
      6'd44: begin
      end // clock_state == 6'd44
      
      6'd52: begin
      end // clock_state == 6'd52
      
      6'd60: begin
      end // clock_state == 6'd60
      
    endcase // clock_State
            
  end // if not reset
end // posedge of clk

endmodule

