## Serial Example Knowledge Base: Architecture and Usage

### Purpose

This article explains the architecture, address decoding, GPIO mapping, firmware usage patterns, and test guidance for the Serial Example project that integrates multiple UART and SPI peripherals into the Caravel user area.

### Top-Level Architecture

- `user_project_wrapper` instantiates `user_peripherals_wrapper` only.
- `user_peripherals_wrapper` aggregates two blocks:
  - `multi_uart_wrapper` (8× CF_UART via Wishbone)
  - `multi_spi_wrapper` (5× CF_SPI via Wishbone)

Wishbone address bits A[19:16] select peripheral pages inside the user window. Responses are OR-combined for ACK and multiplexed for DAT_O.

### Wishbone Address Map

- UART pages: 0x3000_0000 .. 0x3007_FFFF (A[19:16] = 0..7). 64KB-aligned spacing avoids conflicts with 16-bit register offsets used by CF_UART.
- SPI pages:  0x3008_0000 .. 0x300C_FFFF (A[19:16] = 8..12). Also 64KB-aligned.

Example base addresses used in firmware:

- UART0..7: 0x300n0000 (n = 0..7)
- SPI0..4:  0x3008_0000 + n*0x10000

### GPIO Mapping

UARTs:
- RX pins (inputs): 0, 2, 4, 6, 9, 11, 13, 15
- TX pins (outputs): 1, 3, 5, 7, 10, 12, 14, 16

SPIs:
- SPI0: MISO=17 (in), MOSI=18 (out), SCLK=19 (out), CSB=20 (out)
- SPI1: MISO=21, MOSI=22, SCLK=23, CSB=24
- SPI2: MISO=25, MOSI=26, SCLK=27, CSB=28
- SPI3: MISO=29, MOSI=30, SCLK=31, CSB=32
- SPI4: MISO=33, MOSI=34, SCLK=35, CSB=36

The RTL sets `io_oeb` so that inputs are high-Z and outputs drive the expected signals.

### Firmware Usage Patterns

Common sequence (see firmware in `verilog/dv/cocotb/user_proj_tests/`):

1. Configure GPIO directions and modes for used pads
2. Apply configuration with `GPIOs_loadConfigs()`
3. Enable user Wishbone IF with `User_enableIF()`
4. For each peripheral instance:
   - Enable global/peripheral clock (e.g., `CF_UART_setGclkEnable`, `CF_SPI_setGclkEnable`)
   - Configure mode (FIFO thresholds for UART; CPOL/CPHA/prescaler for SPI)
   - Enable TX or SPI controller as needed
5. Transmit/receive data

Before building firmware/tests, install IP dependencies (UART and SPI) with cf-ipm from the repo root:

```bash
pip install cf-ipm
ipm install-dep
```

Reference files:
- Multi-UART FW: `verilog/dv/cocotb/user_proj_tests/multi_uart_test/multi_uart_test.c`
- Multi-SPI  FW: `verilog/dv/cocotb/user_proj_tests/multi_spi_test/multi_spi_test.c`

### Test Guidance (cocotb)

- Test list YAML: `verilog/dv/cocotb/user_proj_tests/user_proj_tests.yaml`
- Run all tests:

  ```bash
  caravel_cocotb -tl verilog/dv/cocotb/user_proj_tests/user_proj_tests.yaml \
    -tag serial_example -design_info verilog/dv/cocotb/design_info.yaml
  ```

- Multi-UART: `multi_uart_test` instantiates 8 UART monitors and checks TX traffic per instance.
- Multi-SPI: `multi_spi_test` captures MOSI bytes while CS is asserted and compares against expected pattern.

### Timing and Hardening Notes

- The primary clock is `wb_clk_i`; period is set via OpenLane config (`CLOCK_PERIOD` = 25ns by default).
- Signoff SDC is in `sdc/user_project_wrapper.sdc`.
- Harden with `make user_project_wrapper` after setting up OpenLane/PDK.

### Troubleshooting

- No Wishbone ACK: ensure `User_enableIF()` is called in firmware.
- No UART output: verify TX GPIOs are configured as user outputs and GCLK is enabled on the selected UART.
- No SPI toggling: confirm CSB/MOSI/SCLK are configured as outputs and the controller is enabled while BUSY indicates transfer.



