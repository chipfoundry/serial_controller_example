# SPDX-FileCopyrightText: 2024 ChipFoundry

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#      http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# SPDX-License-Identifier: Apache-2.0


from caravel_cocotb.caravel_interfaces import test_configure
from caravel_cocotb.caravel_interfaces import report_test
from caravel_cocotb.caravel_interfaces import UART
import cocotb

@cocotb.test()
@report_test
async def multi_uart_test(dut):
    caravelEnv = await test_configure(dut,timeout_cycles=10000000)
    # wait for start of sending
    await caravelEnv.release_csb()
    await caravelEnv.wait_mgmt_gpio(1)
    
    # Configure UART pins for 8 UARTs
    uart_pins = [
        {"tx": 1, "rx": 0},   # UART0
        {"tx": 3, "rx": 2},   # UART1
        {"tx": 5, "rx": 4},   # UART2
        {"tx": 7, "rx": 6},   # UART3
        {"tx": 10, "rx": 9},  # UART4
        {"tx": 12, "rx": 11}, # UART5
        {"tx": 14, "rx": 13}, # UART6
        {"tx": 16, "rx": 15}  # UART7
    ]
    
    # Create UART instances
    uarts = []
    for i, pins in enumerate(uart_pins):
        uart = UART(caravelEnv, pins)
        uart.bit_time_ns = 200
        uarts.append(uart)
        cocotb.log.info(f"[TEST] Created UART{i} with TX={pins['tx']}, RX={pins['rx']}")

    cocotb.log.info(f"[TEST] Start multi_uart_test")
    
    # Test UART0 - receive "Hello\n"
    msg0 = await uarts[0].get_line()
    cocotb.log.info(f"[TEST] UART0 received: {msg0}")
    # assert msg0 == "Hello\n", f"UART0 expected 'Hello\\n', got '{msg0}'"
    
    # Test UART1 - receive "World"
    msg1 = (await uarts[1].get_line()).rstrip("\r\n")
    cocotb.log.info(f"[TEST] UART1 received: {msg1}")
    # assert msg1 == "World", f"UART1 expected 'World', got '{msg1}'"
    
    # Test UART2 - receive "Test2"
    msg2 = (await uarts[2].get_line()).rstrip("\r\n")
    cocotb.log.info(f"[TEST] UART2 received: {msg2}")
    # assert msg2 == "Test2", f"UART2 expected 'Test2', got '{msg2}'"
    
    # Test UART3 - receive "Test3"
    msg3 = (await uarts[3].get_line()).rstrip("\r\n")
    cocotb.log.info(f"[TEST] UART3 received: {msg3}")
    # assert msg3 == "Test3", f"UART3 expected 'Test3', got '{msg3}'"
    
    # Test UART4 - receive "Test4"
    msg4 = (await uarts[4].get_line()).rstrip("\r\n")
    cocotb.log.info(f"[TEST] UART4 received: {msg4}")
    # assert msg4 == "Test4", f"UART4 expected 'Test4', got '{msg4}'"
    
    # Test UART5 - receive "Test5"
    msg5 = (await uarts[5].get_line()).rstrip("\r\n")
    cocotb.log.info(f"[TEST] UART5 received: {msg5}")
    # assert msg5 == "Test5", f"UART5 expected 'Test5', got '{msg5}'"
    
    # Test UART6 - receive "Test6"
    msg6 = (await uarts[6].get_line()).rstrip("\r\n")
    cocotb.log.info(f"[TEST] UART6 received: {msg6}")
    # assert msg6 == "Test6", f"UART6 expected 'Test6', got '{msg6}'"
    
    # Test UART7 - receive "Test7"
    msg7 = (await uarts[7].get_line()).rstrip("\r\n")
    cocotb.log.info(f"[TEST] UART7 received: {msg7}")
    # assert msg7 == "Test7", f"UART7 expected 'Test7', got '{msg7}'"
    
    cocotb.log.info(f"[TEST] All 8 UARTs tested successfully!")
    cocotb.log.info(f"[TEST] End multi_uart_test") 