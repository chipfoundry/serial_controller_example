// SPDX-FileCopyrightText: 2024 ChipFoundry

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

//      http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// SPDX-License-Identifier: Apache-2.0

#include <firmware_apis.h>
#include <CF_UART.h>
#include <CF_UART.c>

// UART0 base address
#define UART0_BASE 0x30000000
#define UART0 ((CF_UART_TYPE_PTR)UART0_BASE)

void main(){
    // Enable management gpio as output to use as indicator for finishing configuration  
    ManagmentGpio_outputEnable();
    ManagmentGpio_write(0);
    enableHkSpi(0); // disable housekeeping spi
    
    // Configure GPIO pins for UART0: TX=1, RX=0
    GPIOs_configure(1, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(0, GPIO_MODE_USER_STD_INPUT_PULLUP);
    
    GPIOs_loadConfigs(); // load the configuration 
    User_enableIF(); // this necessary when reading or writing between wishbone and user project if interface isn't enabled no ack would be recieve and the command will be stuck
    ManagmentGpio_write(1);
    
    // Initialize UART0
    CF_UART_enable(UART0);
    CF_UART_setGclkEnable(UART0, 1);  // Enable clock for UART0
    CF_UART_setTxFIFOThreshold(UART0, 3);
    CF_UART_enableTx(UART0);
    
    // Send "Hello\n" on UART0
    CF_UART_writeChar(UART0, 'H');
    CF_UART_writeChar(UART0, 'e');
    CF_UART_writeChar(UART0, 'l');
    CF_UART_writeChar(UART0, 'l');
    CF_UART_writeChar(UART0, 'o');
    CF_UART_writeChar(UART0, '\n');
} 