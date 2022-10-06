.PHONY: run default clean wave waves
ALL_SRC = $(wildcard src/*.v)
ALL_INC = $(wildcard inc/*.h)

VLG_SRC = $(ALL_SRC)
VLIBS   =

IVL      = iverilog
IVL_DEF  =
IVL_OPTS = -g2012 -s sys -I./inc $(IVL_DEF) $(VLIBS)

WAVE = gtkwave
WV_VCD_FILE  = -f tb.vcd
WV_SAVE_FILE = -a tb.gtkw
WAVE_OPTS = $(WV_VCD_FILE) $(WV_SAVE_FILE) $(WV_RC_FILE)

TARGET = bin/tb
default: run

$(TARGET): $(ALL_SRC) $(ALL_INC)
	-mkdir -p bin
	$(IVL) $(IVL_OPTS)	$(VLG_SRC) -o $@

run: $(TARGET)
	$(TARGET)

waves: wave
wave:
	$(WAVE) $(WAVE_OPTS)  &

clean:
	-rm -f $(TARGET)
	-rm -f $(WV_VCD_FILE)
