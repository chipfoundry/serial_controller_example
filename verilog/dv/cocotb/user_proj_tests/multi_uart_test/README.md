# Multi-UART System

This directory contains tests for the multi-UART system that provides 8 independent UART interfaces.

## Overview

The multi-UART system consists of 8 independent UART instances, each with its own Wishbone interface and GPIO pins. The system uses address decoding to route Wishbone transactions to the appropriate UART.

## UART Configuration

### GPIO Pin Assignments

| UART | TX Pin | RX Pin | Base Address |
|------|--------|--------|--------------|
| UART0 | 1 | 0 | 0x30000000 |
| UART1 | 3 | 2 | 0x30001000 |
| UART2 | 5 | 4 | 0x30002000 |
| UART3 | 7 | 6 | 0x30003000 |
| UART4 | 10 | 9 | 0x30004000 |
| UART5 | 12 | 11 | 0x30005000 |
| UART6 | 14 | 13 | 0x30006000 |
| UART7 | 16 | 15 | 0x30007000 |

### Address Decoding

Each UART gets a 4KB address space (12 bits). The address decoder uses bits 14-12 of the Wishbone address to select the UART:

- UART0: 0x30000000-0x30000FFF (bits 14-12 = 000)
- UART1: 0x30001000-0x30001FFF (bits 14-12 = 001)
- UART2: 0x30002000-0x30002FFF (bits 14-12 = 010)
- UART3: 0x30003000-0x30003FFF (bits 14-12 = 011)
- UART4: 0x30004000-0x30004FFF (bits 14-12 = 100)
- UART5: 0x30005000-0x30005FFF (bits 14-12 = 101)
- UART6: 0x30006000-0x30006FFF (bits 14-12 = 110)
- UART7: 0x30007000-0x30007FFF (bits 14-12 = 111)

## Interrupts

Each UART provides its own interrupt signal. The interrupts are combined into the `user_irq[7:0]` signals:

- `user_irq[0]`: UART0 interrupt
- `user_irq[1]`: UART1 interrupt
- `user_irq[2]`: UART2 interrupt
- `user_irq[3]`: UART3 interrupt
- `user_irq[4]`: UART4 interrupt
- `user_irq[5]`: UART5 interrupt
- `user_irq[6]`: UART6 interrupt
- `user_irq[7]`: UART7 interrupt

## Testing

### Multi-UART Test

The `multi_uart_test` verifies that all 8 UARTs work correctly by:

1. Configuring all GPIO pins for the 8 UARTs
2. Initializing all UARTs with proper settings
3. Sending different messages on each UART
4. Verifying that each UART receives the correct message

### Single UART Test

The `single_uart_test` provides a simpler test that only tests UART0 to verify basic functionality.

## Usage

To use the multi-UART system in your firmware:

1. Include the EF_UART headers
2. Define the UART base addresses
3. Configure the GPIO pins for each UART
4. Initialize each UART with `EF_UART_enable()`
5. Configure TX/RX settings as needed
6. Use `EF_UART_writeChar()` and `EF_UART_readChar()` for communication

## Files

- `multi_uart_test.py`: Testbench for all 8 UARTs
- `multi_uart_test.c`: Firmware that sends messages on all UARTs
- `multi_uart_test.yaml`: Test configuration
- `single_uart_test.py`: Simple test for UART0
- `single_uart_test.c`: Firmware for single UART test
- `single_uart_test.yaml`: Single UART test configuration 