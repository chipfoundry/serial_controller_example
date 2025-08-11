## Serial Example: Multi-UART + Multi-SPI on Caravel User Project

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

### Overview

This repository contains a Caravel user project that integrates:

- 8 independent UARTs (TX/RX on GPIO[0..16])
- 5 independent SPI master instances (MISO/MOSI/SCLK/CSB on GPIO[17..36])

The design exposes all peripherals on the Caravel wishbone user window and maps them to GPIO pads for direct chip IO. It ships with cocotb-based full-chip tests and firmware demonstrating basic TX activity across all instances.

For a deeper architectural walkthrough, see the knowledge base article in `docs/source/serial_example.md`.

### Block Diagram

Top `user_project_wrapper` → `user_peripherals_wrapper` containing:
- `multi_uart_wrapper` (8× CF_UART via Wishbone)
- `multi_spi_wrapper` (5× CF_SPI via Wishbone)

### Address Map (Wishbone user window)

- UART pages: 0x3000_0000 .. 0x3007_FFFF (A[19:16] = 0..7)
- SPI pages:  0x3008_0000 .. 0x300C_FFFF (A[19:16] = 8..12)

Each page is 64KB-aligned. Within a page, the underlying IP may use up to 16-bit register offsets.

### GPIO Map

UARTs (8):

| UART | RX GPIO | TX GPIO |
|------|---------|---------|
| 0    | 0       | 1       |
| 1    | 2       | 3       |
| 2    | 4       | 5       |
| 3    | 6       | 7       |
| 4    | 9       | 10      |
| 5    | 11      | 12      |
| 6    | 13      | 14      |
| 7    | 15      | 16      |

SPIs (5):

| SPI | MISO | MOSI | SCLK | CSB |
|-----|------|------|------|-----|
| 0   | 17   | 18   | 19   | 20  |
| 1   | 21   | 22   | 23   | 24  |
| 2   | 25   | 26   | 27   | 28  |
| 3   | 29   | 30   | 31   | 32  |
| 4   | 33   | 34   | 35   | 36  |

Output enables are configured so that RX and MISO are inputs; TX, MOSI, SCLK, and CSB are outputs.

### Get Started

Prerequisites:
- Docker (recommended) and Python 3.8+

Install IP dependencies:
- Install cf-ipm (ChipFoundry IP Manager):

```bash
pip install cf-ipm
```

- From the repo root, run:

```bash
ipm install-dep   # installs UART and SPI IPs listed in ip/dependencies.json
```

Environment (from repo root):

```bash
make setup-cocotb   # one-time: install cocotb test infra
```

Run all cocotb tests for this project:

```bash
caravel_cocotb -tl verilog/dv/cocotb/user_proj_tests/user_proj_tests.yaml \
  -tag serial_example -design_info verilog/dv/cocotb/design_info.yaml
```

Run individual tests:

```bash
# Multi-UART
caravel_cocotb -t multi_uart_test -tag multi_uart \
  -design_info verilog/dv/cocotb/design_info.yaml

# Multi-SPI
caravel_cocotb -t multi_spi_test -tag multi_spi \
  -design_info verilog/dv/cocotb/design_info.yaml
```

Gate-level (after hardening):

```bash
make cocotb-verify-<test_name>-gl
```

### Hardening with OpenLane

The OpenLane configuration is under `openlane/user_project_wrapper/`. To harden the wrapper (requires PDK and OpenLane setup):

```bash
make user_project_wrapper
```

Timing constraints live in `sdc/user_project_wrapper.sdc`. Signoff artifacts are under `signoff/user_project_wrapper/`.

### Firmware Examples

Reference firmware for the tests is in:
- `verilog/dv/cocotb/user_proj_tests/multi_uart_test/multi_uart_test.c`
- `verilog/dv/cocotb/user_proj_tests/multi_spi_test/multi_spi_test.c`

These demonstrate enabling Wishbone access, configuring GPIO modes, enabling peripheral clocks, and simple transmit sequences.

### Source Layout

- RTL: `verilog/rtl/`
  - `user_project_wrapper.v`, `user_peripherals_wrapper.v`
  - `multi_uart_wrapper.v`, `multi_spi_wrapper.v`
- Tests: `verilog/dv/cocotb/user_proj_tests/`
- OpenLane: `openlane/user_project_wrapper/`
- Signoff: `signoff/user_project_wrapper/`

