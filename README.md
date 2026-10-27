# RV32I Single-Cycle Core + Bare-Metal Button/LED Firmware

![simulate](https://github.com/Ofrank-design/bootloader-cpu/actions/workflows/ci.yml/badge.svg)

A synthesizable single-cycle RISC-V (RV32I subset) CPU core written in SystemVerilog, wired into a small memory-mapped SoC and verified by running a hand-written bare-metal assembly program on it. The firmware reads a button through a GPIO register and toggles an LED, once per press.

The project combines two exercises:

1. **Hardware:** a single-cycle RV32I core (decoder, register file, ALU, control unit, PC).
2. **Firmware:** a bare-metal assembly program that controls hardware directly through MMIO, with no operating system.

The testbench drives the button pin, runs the real firmware on the real core, and checks the LED pin.

## Quick start

Requirements: [Verilator](https://verilator.org) 5.x and `make`.

```bash
sudo apt install verilator      # Ubuntu/Debian (macOS: brew install verilator)
git clone https://github.com/<your-username>/<your-repo>.git
cd <your-repo>
make all
```

Expected output:

```
PASS: decoder
ok   idle after reset: LED=0
ok   after press (toggle 1): LED=1
ok   still held (no re-toggle): LED=1
ok   after release: LED=1
ok   second press (toggle 2): LED=0
ok   after second release: LED=0
PASS: SoC runs button/LED firmware correctly
```

Windows users should use WSL. Build files go to `/tmp/rv32i_build` by default; override with `make BUILD=<dir>`.

To rebuild `fw/firmware.hex` from the assembly source (requires `binutils-riscv64-unknown-elf`):

```bash
make fw
```

## Architecture

```
            +-----------------------------------------+
            |                  soc                    |
            |                                         |
 imem  <----+--  rv32i_core  ----+---> dmem (RAM)     |
 (ROM)      |   pc, decoder,     |                    |
            |   control, regfile,+---> gpio  <--- pins_in[0]  (button)
            |   alu              |         ---> pins_out[1] (LED)
            +-----------------------------------------+
```

The core is Harvard-style: separate instruction and data buses, both with asynchronous reads, so every instruction completes in one clock cycle.

### Memory map

| Range | Device |
|---|---|
| `0x0000_0000` upward | Instruction ROM (loaded from `fw/firmware.hex`) |
| `0x4000_0000` – `0x4FFF_FFFF` | GPIO peripheral |
| Any other data address | Data RAM (256 words, wraps) |

### GPIO registers

| Address | Register | Access | Description |
|---|---|---|---|
| `0x4000_0000` | `GPIO_DATA` | R/W | Read: live input on input pins, output latch on output pins. Write: output latch |
| `0x4000_0004` | `GPIO_DIR` | R/W | 1 = output, 0 = input |
| `0x4000_0008` | `GPIO_SET` | W | Set the given bits in the output latch |
| `0x4000_000C` | `GPIO_CLR` | W | Clear the given bits in the output latch |

Pin assignment: bit 0 is the button (input), bit 1 is the LED (output).

**This register map is illustrative.** It is a model written for this project, not any real chip's peripheral. Confirm addresses and behavior against the reference manual before pointing this firmware at real hardware.

## Supported instructions

| Format | Instructions |
|---|---|
| U-type | `LUI` |
| I-type ALU | `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI` |
| R-type ALU | `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND` |
| Load / store | `LW`, `SW` (word access only) |
| Branch | `BEQ`, `BNE` |
| Jump | `JAL` |

Unsupported opcodes currently behave as NOPs. There is no illegal-instruction trap yet.

## Firmware

`fw/button_led.S` does the following:

1. Loads the GPIO base address with `lui`.
2. Sets pin 1 as an output (read-modify-write on `GPIO_DIR`).
3. Polls the button until it reads high.
4. Toggles the LED bit in `GPIO_DATA`.
5. Runs a software delay loop (100 iterations).
6. Waits for the button to be released, then returns to polling.

The release wait ensures one press produces one toggle, even if the button is held. It does **not** debounce a real mechanical switch.

## Repository layout

```
rtl/        core, decoder, ALU, register file, control, PC, memories, GPIO, SoC top
tb/         tb_instr_decoder.sv (decoder checks), tb_soc.sv (full-system test)
fw/         button_led.S (source) and firmware.hex (assembled image)
Makefile    build and test targets
.github/    CI workflow
```

## Continuous integration

Every push runs `.github/workflows/ci.yml`, which:

- reassembles `button_led.S` and fails if it differs from the committed `firmware.hex`;
- runs the decoder testbench;
- runs the full SoC testbench.

## Verification status

- Decoder: field extraction and all five immediate formats checked against encodings from the real firmware.
- SoC: the firmware runs end to end in Verilator, including the hold-without-retoggle case.
- `firmware.hex` is cross-checked against the output of the GNU RISC-V assembler.

Not yet done: formal verification, riscv-tests / compliance suite, synthesis, and hardware bring-up.

## Known limitations

- Word-only memory access (no `LB`, `LBU`, `LH`, `LHU`, `SB`, `SH`).
- No `JALR`, `AUIPC`, `BLT`, `BGE`, `BLTU`, `BGEU`.
- No CSRs, interrupts, or trap handling.
- Asynchronous-read memories simulate well but will need to change for FPGA block RAM.
- The GPIO model is hypothetical.
- Not timing-closed or synthesized for any target.

## Roadmap

- [ ] Byte and halfword loads/stores (needed for an LED-matrix frame buffer)
- [ ] `JALR`, `AUIPC`, remaining branches
- [ ] Illegal-instruction flag
- [ ] LED matrix driver (row/column scan from a frame buffer)
- [ ] Button debouncing
- [ ] Linker script and startup code (stack, `.data`/`.bss` init)
- [ ] Run the official RISC-V compliance tests
- [ ] FPGA target (constraints file, block-RAM memories)

## License

Add a license of your choice (MIT is common for projects like this) before publishing.
