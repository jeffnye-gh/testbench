// ------------------------------------------------------------------------
// Basically a RAM with a req/ready wait state interface
// Copyright (c) 2022 Jeff Nye
// ------------------------------------------------------------------------

`include "sim_defs.h"
module dut #(
  parameter [2:0] WAIT_STATES = 0
)
(
  output reg       ready,
  output reg [7:0] readdata,  //only driven when ready is active

  input  wire [7:0] addr,
  input  wire read,
  input  wire write,

  input  wire [7:0] writedata, 

  input  wire reset,
  input  wire clk
);
// ----------------------------------------------------------------
reg [7:0] readdata_o;
reg [7:0] readdata_q[0:3];
reg       ready_q[0:3];
reg [7:0] ram[0:255];
reg ready_d;
// ----------------------------------------------------------------
assign readdata = ready ? readdata_o : 8'bx;
assign access   = read|write;
// ----------------------------------------------------------------
always @(posedge clk) ram[addr] <= write ? writedata : ram[addr];
wire [7:0] rd_data = ram[addr];
// ----------------------------------------------------------------
wire [7:0] ram_00 = ram[8'h00];
wire [7:0] ram_34 = ram[8'h34];
wire [7:0] ram_56 = ram[8'h56];
wire [7:0] ram_78 = ram[8'h78];
wire [7:0] ram_9a = ram[8'h9a];
// ----------------------------------------------------------------
always @* begin
  case(WAIT_STATES) 
    4: readdata_o = readdata_q[3];
    3: readdata_o = readdata_q[2];
    2: readdata_o = readdata_q[1];
    1: readdata_o = readdata_q[0];
    0: readdata_o = rd_data; //$unsigned(addr+1'b1);
    default: readdata_o = 8'bx;
  endcase 

  case(WAIT_STATES) 
    4: ready = ready_q[3];
    3: ready = ready_q[2];
    2: ready = ready_q[1];
    1: ready = ready_q[0];
    0: ready = access;
    default: ready = 1'bx;
  endcase 
end
// ----------------------------------------------------------------
always @(posedge clk) begin
  readdata_q[0] <= rd_data;
  readdata_q[1] <= readdata_q[0];
  readdata_q[2] <= readdata_q[1];
  readdata_q[3] <= readdata_q[2];

  ready_q[0] <= `FF ready_d;
  ready_q[1] <= `FF ready_q[0];
  ready_q[2] <= `FF ready_q[1];
  ready_q[3] <= `FF ready_q[2];
end

// ----------------------------------------------------------------
always @* begin
  case(WAIT_STATES) 
    4: ready_d = access&!ready&!ready_q[0]&!ready_q[1]&!ready_q[2];
    3: ready_d = access&!ready&!ready_q[0]&!ready_q[1];
    2: ready_d = access&!ready&!ready_q[0];
    1: ready_d = access&!ready;
    0: ready_d = access;
    default: ready_d = 1'bx;
  endcase 
end

// I generate based version, not optimal, kept for reference. 
// FIXME: come back and make sure this works the same as the version
// above.
//
//generate 
//  // ----------------------------------------------------------------
//  // 4 wait state case
//  // ----------------------------------------------------------------
//  if(WAIT_STATES == 4) begin
//    reg       ready_q0,ready_q1,ready_q2;
//    reg [7:0] readdata_q0,readdata_q1,readdata_q2;
//    always @(posedge clk) begin
//      ready_q0   <= read&!ready&!ready_q0&!ready_q1&!ready_q2;
//      ready_q1   <= ready_q0;
//      ready_q2   <= ready_q1;
//      ready      <= ready_q2;
//
//      readdata_q0 <= addr+1;
//      readdata_q1 <= readdata_q0;
//      readdata_q2 <= readdata_q1;
//      readdata_o  <= readdata_q2;
//    end
//  end
//
//  // ----------------------------------------------------------------
//  // 3 wait state case
//  // ----------------------------------------------------------------
//  else if(WAIT_STATES == 3) begin
//    reg       ready_q0,ready_q1;
//    reg [7:0] readdata_q0,readdata_q1;
//    always @(posedge clk) begin
//      ready_q0   <= read&!ready&!ready_q0&!ready_q1;
//      ready_q1   <= ready_q0;
//      ready      <= ready_q1;
//
//      readdata_q0 <= addr+1;
//      readdata_q1 <= readdata_q0;
//      readdata_o  <= readdata_q1;
//    end
//  end
//
//  // ----------------------------------------------------------------
//  // 2 wait state case
//  // ----------------------------------------------------------------
//  if(WAIT_STATES == 2) begin
//    reg       ready_q0;
//    reg [7:0] readdata_q0;
//    always @(posedge clk) begin
//      ready_q0   <= read&!ready&!ready_q0;
//      ready      <= ready_q0;
//
//      readdata_q0 <= addr+1;
//      readdata_o <= readdata_q0;
//    end
//  end
//
//  // ----------------------------------------------------------------
//  // 1 wait state case
//  // ----------------------------------------------------------------
//  else if(WAIT_STATES == 1) begin
//    always @(posedge clk) begin
//      ready      <= read&!ready;
//      readdata_o <= addr+1;
//    end
//  end
//
//  // ----------------------------------------------------------------
//  // 0 wait state case
//  // ----------------------------------------------------------------
//
//  else if(WAIT_STATES == 0) begin
//    always @* begin
//      ready      = read;
//      readdata_o = addr+1;
//    end
//  end
//
//endgenerate
endmodule
