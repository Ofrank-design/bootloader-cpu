RTL = rtl/alu.sv rtl/control.sv rtl/instr_decoder.sv rtl/regfile.sv rtl/pc.sv rtl/imem.sv rtl/dmem.sv rtl/rv32i_core.sv rtl/gpio.sv rtl/soc.sv
BUILD ?= /tmp/rv32i_build
VFLAGS = --binary --timing -Wno-fatal -Wno-TIMESCALEMOD

all: dec soc

dec:
	mkdir -p $(BUILD)
	verilator $(VFLAGS) -Mdir $(BUILD)/dec --top-module tb_instr_decoder rtl/instr_decoder.sv tb/tb_instr_decoder.sv
	$(BUILD)/dec/Vtb_instr_decoder

soc:
	mkdir -p $(BUILD)
	verilator $(VFLAGS) -Mdir $(BUILD)/soc --top-module tb_soc $(RTL) tb/tb_soc.sv
	$(BUILD)/soc/Vtb_soc

# Rebuild firmware.hex from assembly (needs riscv64-unknown-elf binutils)
fw:
	riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 fw/button_led.S -o fw/fw.o
	riscv64-unknown-elf-objcopy -O binary -j .text fw/fw.o fw/fw.bin
	python3 -c "import struct;b=open('fw/fw.bin','rb').read();print('\n'.join(f'{w:08X}' for w in struct.unpack('<%dI'%(len(b)//4),b)))" > fw/firmware.hex

clean:
	rm -rf $(BUILD) fw/fw.o fw/fw.bin
