// vi:syntax=verilog
// -------------------------------------------------------------
// Tasks called from the top level, sys.v
// Copyright (c) 2022 Jeff Nye
// -------------------------------------------------------------
// Issue an in-line read of the dut's ram
// -------------------------------------------------------------
task read(input [7:0] addr,input int id,input int verbose=0);
begin
  if(verbose) $display("READ  REQ id:%0d",id);
  tb_dut_addr        <= `FF addr;
  tb_dut_read        <= `FF 1'b1;
  tb_dut_write       <= `FF 1'b0;
  tb_dut_writedata   <= `FF 8'bx;
  //I dont think icarus supports iff, this works
  do @(posedge clk); while(!dut_tb_ready);
  tb_dut_read        <= `FF 1'b0;
  tb_dut_write       <= `FF 1'b0;
  tb_dut_addr        <= `FF 8'bx;
end
endtask
// -------------------------------------------------------------
// Issue an in-line write to the dut's ram
// -------------------------------------------------------------
task write(input [7:0] addr,input [7:0] wd,input int id,input int verbose=0);
begin
  if(verbose) $display("WRITE REQ id:%0d",id);
  tb_dut_addr        <= `FF addr;
  tb_dut_read        <= `FF 1'b0;
  tb_dut_write       <= `FF 1'b1;
  tb_dut_writedata   <= `FF wd;
  do @(posedge clk); while(!dut_tb_ready);
  tb_dut_read        <= `FF 1'b0;
  tb_dut_write       <= `FF 1'b0;
  tb_dut_addr        <= `FF 8'bx;
end
endtask
// -------------------------------------------------------------
// NOP
// -------------------------------------------------------------
task nop(input int cnt,input int verbose=0);
integer i;
begin
  if(verbose) $display("NOP cnt %0d",cnt);
  tb_dut_read  <= `FF 1'b0;
  tb_dut_write <= `FF 1'b0;
  @(posedge clk);
  for(i=0;i<cnt-1;i+=1) @(posedge clk);
end
endtask
// -------------------------------------------------------------
// SHOW RAM contents
// -------------------------------------------------------------
task dump_ram(input int _start,input int _end=256);
integer i;
begin
  $display("-I: dut ram contents");
  for(i=_start;i<_end;i=i+1) begin
    $display("-I: a:%02x d:%02x",i[7:0],sys.dut0.ram[i]);
  end
end
endtask
// -------------------------------------------------------------
// CHECK CAPTURE contents
// verify the capture array matches the specified file
// -------------------------------------------------------------
task verify_capture(inout int errs,input string _file,input int _start=0,
                    input int _end=1024,input int verbose=0);
integer i;
reg [15:0] expected[0:1024];
reg [7:0]  actual_d,actual_a,expect_d,expect_a;
int match_a,match_d;
begin
  if(verbose) $display("-I: verify capture buffer contents");
  $readmemh(_file,expected);
  for(i=_start;i<_end;i=i+1) begin

    actual_a = sys.capture_addr[i];
    actual_d = sys.capture_data[i];

    expect_a = expected[i][15: 8];
    expect_d = expected[i][ 7: 0];

    match_a  = actual_a === expect_a;
    match_d  = actual_d === expect_d;

    if(!match_a || !match_d) begin
      errs = errs + 1;
      $display(
        "-E: idx:%02x aexp:%02x aact:%02x dexp:%02x dact:%02x, a:%0d d:%0d",
               i[7:0],expect_a,actual_a,expect_d,actual_d,match_a,match_d);
    end else if(verbose) begin
      $display(
        "-i: idx:%02x aexp:%02x aact:%02x dexp:%02x dact:%02x, a:%0d d:%0d",
               i[7:0],expect_a,actual_a,expect_d,actual_d, match_a,match_d);
    end
  end
end
endtask
// -------------------------------------------------------------
// CHECK RAM contents
// verify the dut ram matches the specified file
// -------------------------------------------------------------
task verify_ram(inout int errs,input string _file,input int _start=0,
                input int _end=256,input int verbose=0);
integer i;
reg [7:0] expected[0:255];
reg [7:0] actual;
integer match;
begin
  //if(verbose) $display("-I: verify ram contents");
  $readmemh(_file,expected);
  for(i=_start;i<_end;i=i+1) begin

    actual = sys.dut0.ram[i];
    match  = actual === expected[i];

    if(!match) begin
      errs += 1;
      $display("-E: add:%02x exp:%02x act:%02x %0d mismatch",
               i[7:0],expected[i],actual,match);
    end else if(verbose) begin
      $display("-I: add:%02x exp:%02x act:%02x %0d",
               i[7:0],expected[i],actual,match);
    end

  end
end
endtask

