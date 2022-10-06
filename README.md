Copyright (c) 2022 Jeff Nye

# Testbench template

## TL;DR

This is my template for a unit test environment. It's mostly for jogging
my memory, I can't always get to my home machine. I cut and paste then 
build on it depending on the unit I'm designing. It is the basis of the
test environment in my cache generator.

## More
This is a very simple testbench, but it has some core common features:

  * self checking tests
    * readmemh based initialization
    * readmemh based golden data
  * capture array
    * capture address and data for read transactions
  * task based transactions
    * includes ready/valid handshake
  * watchdog timer for run away simulations
  * dumpvars

There is a macro in sim_defs.h which can be used to add a delay in non-
blocking assignments, an old school idiom not necessary in commercial
verilog simulators but there just in case.

The dut is not a useful piece of hardware. It's purpose is to make sure
the testbench mechanics can be exercised.  The dut contains a small ram 
and the dut's interface supports a variable wait state handshake, 
0 - 4 wait states are supported. Number of wait states is a static 
instance parameter.  Synthesis will eliminate the unused logic.
 
The number of wait states is contolled by a localparam TB_WAIT_STATES.
This could easily be passed as a port in the dut interface.

And TB_WAIT_STATES could be passed as a -D, I have it in sys.v to trigger
recompile when I change it. 

The implementation could be modified to make wait state insertion
dynamic, maybe for region/address based delays. That is left as an
exercise.

My coding style may show my Verilog-XL/2K roots but there are also some
limits imposed by the open-source simulator I used. Icarus Verilog is
a great tool. I use it at home. It does not support all of SystemVerilog
but I do not find it limiting. Using modelsim or other FPGA based 
simulators would allow more inclusion of SystemVerilog-isms. Another
exercise.

## Editorial
I've seen a number of youtube videos using #delays in-line in an initial 
block to stage control signals. I do not think the testbenches in those 
on-line tutorials are the right place to start.

This test bench uses a task based approach and I believe it is still
easy to understand. I think this is a better stepping stone to a UVM or 
other production test bench implementations. 

## Usage

Usage is simple:

* Have icarus verilog in your path, or modify the make file
* make 
* expected console output

```
mkdir -p bin
iverilog -g2012 -s sys -I./inc          src/dut.v src/sys.v -o bin/tb
bin/tb
VCD info: dumpfile tb.vcd opened for output.
TB_WAIT_STATES 0
-I: verify init ram contents    PASS
-I: verify capture ram contents PASS
-I: verify final ram contents   PASS
```

* There is a sample GTKWave signal list
* make waves
