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
