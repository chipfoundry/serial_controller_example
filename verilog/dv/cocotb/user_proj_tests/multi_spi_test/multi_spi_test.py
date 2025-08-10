# SPDX-FileCopyrightText: 2024 ChipFoundry
# SPDX-License-Identifier: Apache-2.0

from caravel_cocotb.caravel_interfaces import test_configure
from caravel_cocotb.caravel_interfaces import report_test
import cocotb
from cocotb.triggers import Timer


async def capture_mosi_poll(caravelEnv, sclk_pin, csb_pin, mosi_pin, num_bits=8, timeout_ns=2_000_000):
    bits = []
    # Wait for CSB to go low (active), polling with timeout
    waited = 0
    while caravelEnv.monitor_gpio(csb_pin).integer != 0:
        await Timer(100, units="ns")
        waited += 100
        if waited >= timeout_ns:
            return bits
    # Polling-based edge detection on SCLK
    prev = caravelEnv.monitor_gpio(sclk_pin).integer
    waited = 0
    while len(bits) < num_bits and caravelEnv.monitor_gpio(csb_pin).integer == 0:
        await Timer(100, units="ns")
        waited += 100
        if waited >= timeout_ns:
            break
        curr = caravelEnv.monitor_gpio(sclk_pin).integer
        if prev == 0 and curr == 1:
            bits.append(caravelEnv.monitor_gpio(mosi_pin).integer & 0x1)
        prev = curr
    return bits


@cocotb.test()
@report_test
async def multi_spi_test(dut):
    caravelEnv = await test_configure(dut, timeout_cycles=10_000_000)
    await caravelEnv.release_csb()
    await caravelEnv.wait_mgmt_gpio(1)

    # SPI pin maps per wrapper:
    # SPI0: MISO=17, MOSI=18, SCLK=19, CSB=20
    # SPI1: MISO=21, MOSI=22, SCLK=23, CSB=24
    # SPI2: MISO=25, MOSI=26, SCLK=27, CSB=28
    # SPI3: MISO=29, MOSI=30, SCLK=31, CSB=32
    # SPI4: MISO=33, MOSI=34, SCLK=35, CSB=36
    spi_pads = [
        {"miso": 17, "mosi": 18, "sclk": 19, "csb": 20},
        {"miso": 21, "mosi": 22, "sclk": 23, "csb": 24},
        {"miso": 25, "mosi": 26, "sclk": 27, "csb": 28},
        {"miso": 29, "mosi": 30, "sclk": 31, "csb": 32},
        {"miso": 33, "mosi": 34, "sclk": 35, "csb": 36},
    ]

    # Expected bytes sent by firmware on MOSI: 0xA0 + index
    expected = [0xA0 + i for i in range(len(spi_pads))]

    # Verify each SPI instance toggles as expected
    for i, pads in enumerate(spi_pads):
        # Capture MOSI bits for one byte while CS asserted
        bits = await capture_mosi_poll(caravelEnv, pads["sclk"], pads["csb"], pads["mosi"], num_bits=8)
        # Convert bits (MSB first) into byte
        byte = 0
        for b in bits:
            byte = (byte << 1) | b
        cocotb.log.info(f"[TEST] SPI{i} MOSI byte: 0x{byte:02X}")
        assert byte == expected[i], f"SPI{i} expected 0x{expected[i]:02X}, got 0x{byte:02X}"

    cocotb.log.info("[TEST] multi_spi_test completed successfully")


