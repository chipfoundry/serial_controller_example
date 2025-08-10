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
async def single_uart_test(dut):
    caravelEnv = await test_configure(dut,timeout_cycles=62620)
    # wait for start of sending
    await caravelEnv.release_csb()
    await caravelEnv.wait_mgmt_gpio(1)
    
    # Test UART0 (pins 0,1)
    uart_pins = {"tx": 1, "rx": 0}
    uart = UART(caravelEnv, uart_pins)
    uart.bit_time_ns = 200

    cocotb.log.info(f"[TEST] Start single_uart_test")
    msg = await uart.get_line()
    cocotb.log.info(f"[TEST] Received message: {msg}")
    assert msg == "Hello\n", f"Expected 'Hello\\n', got '{msg}'"
    cocotb.log.info(f"[TEST] End single_uart_test") 