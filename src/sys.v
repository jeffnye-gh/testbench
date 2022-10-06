// vi:syntax=verilog
// ------------------------------------------------------------------------
// Testbench example top level file
//
// This is my template for a unit test environment. 
//
// See README.txt
// Copyright (c) 2022 Jeff Nye
// ------------------------------------------------------------------------
module sys;
`include "sim_defs.h"    //simulator controls
`include "sys_tasks.h"   //system level tasks, tests etc.

localparam [2:0] TB_WAIT_STATES = 0; //0-4 supported;
localparam int MAX = 1024;

int watch_dog,capture_idx,init_errors,capture_errors,ram_expect_errors,id;

//reg has 3 letters, logic has 5, reg wins
reg master_clk,clk,reset,tb_dut_read,tb_dut_write,dut_tb_ready;
reg [7:0]  tb_dut_addr,dut_tb_readdata,tb_dut_writedata;

reg [7:0]  capture_addr[0:1023];
reg [7:0]  capture_data[0:1023];

wire [7:0]  capture_addr_0 = capture_addr[0];
wire [7:0]  capture_data_0 = capture_data[0];
// -------------------------------------------------------------
// -------------------------------------------------------------
initial begin
  watch_dog  = 0;
  master_clk = 1'b0;
  clk        = 1'b0;
  reset      = 1'b0;

  init_errors       = 0;
  capture_errors    = 0;
  ram_expect_errors = 0;

  capture_errors = 0;
  capture_idx    = 0;

  tb_dut_read  = 1'b0;
  tb_dut_write = 1'b0;
  tb_dut_addr  = 8'bx;

  $dumpfile("tb.vcd");
  $dumpvars(0,sys);

  $display("TB_WAIT_STATES %0d",TB_WAIT_STATES);
  run_tests();
end
// ------------------------------------------------------------------------
// Primary test, very simple, not exhaustive
//
// transactions implemented in tasks, see sys_tasks.h
// some nops scattered for variety.
//
// Another exercise: implementat a transcript based task version
// so test can be read from file, then can skip compile for test changes
// ------------------------------------------------------------------------
task run_tests;
begin
  nop(5);                       //add some pad at start of waves
  while(reset) @(posedge clk);  //wait for reset to deassert

  capture_idx       = 0;

  ram_expect_errors = 0; //three error types init, capture, final value
  capture_errors    = 0;
  init_errors       = 0;

  nop(1);
  $readmemh("data/ram_init.memh",dut0.ram);
  //dump_ram(0,8);

  //auto-check the results of the init
  verify_ram(init_errors,"data/ram_init.memh",0,8,0);
  if(init_errors == 0) $display("-I: verify init ram contents    PASS");
  else                 $display("-E: verify init ram contents    FAIL");

  //id is a placeholder for more sophisticated error checking
  id = 0;

  //read some addresses
  read(8'h00,id);  id = id+1;
  read(8'h12,id);  id = id+1;
  nop(1);

  read(8'h34,id);  id = id+1;
  nop(1);
  read(8'h56,id);  id = id+1;
  read(8'h9a,id);  id = id+1;

  nop(5);

  //write some addresses
  write(8'h00,8'hB0,id); id = id+1;
  nop(1);
  write(8'h34,8'hC1,id); id = id+1;
  nop(1); 
  write(8'h56,8'hD2,id); id = id+1;
  write(8'h78,8'hE3,id); id = id+1;
  write(8'h9a,8'hF4,id); id = id+1;

  nop(5);

  //write and read some addresses
  write(8'h12,8'hB0,id); id = id+1;
  read (8'h34,id);       id = id+1;
  read (8'h56,id);       id = id+1;
  write(8'h78,8'hE3,id); id = id+1;
  read (8'h9a,id);       id = id+1;
  write(8'h35,8'h78,id); id = id+1;
  read (8'h78,id);       id = id+1;
  write(8'h55,8'h2d,id); id = id+1;
  read (8'h12,id);       id = id+1; //read requests
  write(8'h9a,8'hF4,id); id = id+1;

  //check the capture array
  verify_capture(capture_errors,   "data/ram_capture_expect.memh",0, 10,0);
  if(capture_errors == 0) $display("-I: verify capture ram contents PASS");
  else                    $display("-E: verify capture ram contents FAIL");

  //check the final value of the dut ram
  verify_ram    (ram_expect_errors,"data/ram_final_expect.memh",  0,256,0);
  if(ram_expect_errors == 0) $display("-I: verify final ram contents   PASS");
  else                       $display("-E: verify final ram contents   FAIL");

  nop(5); //add some pad at the end of waves
  $finish;
end
endtask
// -----------------------------------------------------------------------
// canonical clk generation
// -----------------------------------------------------------------------
always master_clk = `DLY !master_clk;
always @(posedge master_clk) clk <= `FF !clk;
// -----------------------------------------------------------------------
// the read data capture logic
// -----------------------------------------------------------------------
always @(posedge clk) begin
  if(dut_tb_ready && tb_dut_read) begin
    capture_data[capture_idx] <= `FF dut_tb_readdata;
    capture_addr[capture_idx] <= `FF tb_dut_addr;
    capture_idx += 1;
  end
end
// -----------------------------------------------------------------------
// in case the dut never returns ready
// -----------------------------------------------------------------------
always @(posedge clk) begin
  watch_dog <= `FF watch_dog + 1;
  reset     <= `FF (watch_dog <= 5) ? 1'b1 : 1'b0;
  if(watch_dog > MAX) begin
    $display("-E: watch dog time out");
    $finish; 
  end
end
// -----------------------------------------------------------------------
// -----------------------------------------------------------------------
dut #(.WAIT_STATES(TB_WAIT_STATES)) dut0(
  .ready(dut_tb_ready),
  .readdata(dut_tb_readdata),

  .addr (tb_dut_addr),
  .read (tb_dut_read),
  .write(tb_dut_write),
  .writedata(tb_dut_writedata),

  .reset(reset),
  .clk(clk)
);

endmodule
