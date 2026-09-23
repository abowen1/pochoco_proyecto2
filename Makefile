PYTHON ?= python3
TOP ?= board_test_top
MEM := $(if $(filter diagnostic_top,$(TOP)),sw/diagnostic.hex,$(if $(filter game_top,$(TOP)),sw/game.hex,$(if $(filter timer_test_top,$(TOP)),sw/timer_test.hex,sw/buttons_leds.hex)))
ICE40_CELLS ?= $(shell yosys-config --datdir)/ice40/cells_sim.v
SRC := $(wildcard rtl/*.v rtl/espino_core/*.v)
.PHONY: all build program assemble test
all: build
build: build/$(TOP).bin
build/$(TOP).json: $(SRC) $(MEM)
	mkdir -p build
	yosys -p "read_verilog $(SRC); synth_ice40 -top $(TOP) -json $@; stat"
build/$(TOP).asc: build/$(TOP).json goboard.pcf Makefile
	nextpnr-ice40 --hx1k --package vq100 --json $< --pcf goboard.pcf --asc $@ --freq 25
build/$(TOP).bin: build/$(TOP).asc
	icepack $< $@
program: build/$(TOP).bin
	iceprog $<

assemble: sw/buttons_leds.hex
sw/%.hex: sw/%.s tools/assembler.py
	$(PYTHON) tools/assembler.py $< -o $@
test:
	$(PYTHON) -m unittest discover -s tests -v

.PHONY: test-counter test-soc build-timer program-timer
test-counter:
	mkdir -p build
	iverilog -g2012 -s tb_counter -o build/tb_counter tests/tb_counter.v rtl/pochoco_periph.v
	vvp build/tb_counter
test-soc:
	mkdir -p build
	$(PYTHON) tests/make_fast_timer.py
	iverilog -g2012 -DNO_ICE40_DEFAULT_ASSIGNMENTS -s tb_timer_soc -o build/tb_timer_soc tests/tb_timer_soc.v $(SRC) $(ICE40_CELLS)
	vvp build/tb_timer_soc
build-timer:
	$(MAKE) TOP=timer_test_top build
program-timer:
	$(MAKE) TOP=timer_test_top program

.PHONY: build-game program-game test-game
build-game:
	$(MAKE) TOP=game_top build
program-game:
	$(MAKE) TOP=game_top program
test-game:
	mkdir -p build
	$(PYTHON) tests/make_fast_game.py
	iverilog -g2012 -DNO_ICE40_DEFAULT_ASSIGNMENTS -s tb_game -o build/tb_game tests/tb_game.v $(SRC) $(ICE40_CELLS)
	vvp build/tb_game

.PHONY: build-diagnostic program-diagnostic
build-diagnostic:
	$(MAKE) TOP=diagnostic_top build
program-diagnostic:
	$(MAKE) TOP=diagnostic_top program
