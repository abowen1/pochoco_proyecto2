PYTHON ?= python3
.PHONY: all
all: buttons_leds.hex
%.hex: %.s ../tools/assembler.py
	$(PYTHON) ../tools/assembler.py $< -o $@
