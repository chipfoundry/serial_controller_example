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

// UART base addresses for 8 UARTs (64KB spacing to avoid overlap with 16-bit register offsets)
// CF_UART uses 16-bit register addresses up to 0xFFFF (e.g. 0xFF10), so each UART must be 64KB aligned
// within the user project's Wishbone window.
// UARTn @ 0x300n0000
#define UART0_BASE 0x30000000
#define UART1_BASE 0x30010000
#define UART2_BASE 0x30020000
#define UART3_BASE 0x30030000
#define UART4_BASE 0x30040000
#define UART5_BASE 0x30050000
#define UART6_BASE 0x30060000
#define UART7_BASE 0x30070000

#define UART0 ((CF_UART_TYPE_PTR)UART0_BASE)
#define UART1 ((CF_UART_TYPE_PTR)UART1_BASE)
#define UART2 ((CF_UART_TYPE_PTR)UART2_BASE)
#define UART3 ((CF_UART_TYPE_PTR)UART3_BASE)
#define UART4 ((CF_UART_TYPE_PTR)UART4_BASE)
#define UART5 ((CF_UART_TYPE_PTR)UART5_BASE)
#define UART6 ((CF_UART_TYPE_PTR)UART6_BASE)
#define UART7 ((CF_UART_TYPE_PTR)UART7_BASE)

void main(){
    // Enable management gpio as output to use as indicator for finishing configuration  
    ManagmentGpio_outputEnable();
    ManagmentGpio_write(0);
    enableHkSpi(0); // disable housekeeping spi
    
    // Configure GPIO pins for 8 UARTs
    // UART0: TX=1, RX=0
    GPIOs_configure(1, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(0, GPIO_MODE_USER_STD_INPUT_PULLUP);
    
    // UART1: TX=3, RX=2
    GPIOs_configure(3, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(2, GPIO_MODE_USER_STD_INPUT_PULLUP);
    
    // UART2: TX=5, RX=4
    GPIOs_configure(5, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(4, GPIO_MODE_USER_STD_INPUT_PULLUP);
    
    // UART3: TX=7, RX=6
    GPIOs_configure(7, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(6, GPIO_MODE_USER_STD_INPUT_PULLUP);
    
    // UART4: TX=10, RX=9
    GPIOs_configure(10, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(9, GPIO_MODE_USER_STD_INPUT_PULLUP);
    
    // UART5: TX=12, RX=11
    GPIOs_configure(12, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(11, GPIO_MODE_USER_STD_INPUT_PULLUP);
    
    // UART6: TX=14, RX=13
    GPIOs_configure(14, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(13, GPIO_MODE_USER_STD_INPUT_PULLUP);
    
    // UART7: TX=16, RX=15
    GPIOs_configure(16, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(15, GPIO_MODE_USER_STD_INPUT_PULLUP);
    
    GPIOs_loadConfigs(); // load the configuration 
    User_enableIF(); // this necessary when reading or writing between wishbone and user project if interface isn't enabled no ack would be recieve and the command will be stuck
    
    ManagmentGpio_write(1);
    
    // Initialize all UARTs
    CF_UART_enable(UART0);
    CF_UART_enable(UART1);
    CF_UART_enable(UART2);
    CF_UART_enable(UART3);
    CF_UART_enable(UART4);
    CF_UART_enable(UART5);
    CF_UART_enable(UART6);
    CF_UART_enable(UART7);
    // Ensure UART clocks are enabled (required for TX/RX activity)
    CF_UART_setGclkEnable(UART0, 1);
    CF_UART_setGclkEnable(UART1, 1);
    CF_UART_setGclkEnable(UART2, 1);
    CF_UART_setGclkEnable(UART3, 1);
    CF_UART_setGclkEnable(UART4, 1);
    CF_UART_setGclkEnable(UART5, 1);
    CF_UART_setGclkEnable(UART6, 1);
    CF_UART_setGclkEnable(UART7, 1);
    
    // Set TX FIFO thresholds
    CF_UART_setTxFIFOThreshold(UART0, 3);
    CF_UART_setTxFIFOThreshold(UART1, 3);
    CF_UART_setTxFIFOThreshold(UART2, 3);
    CF_UART_setTxFIFOThreshold(UART3, 3);
    CF_UART_setTxFIFOThreshold(UART4, 3);
    CF_UART_setTxFIFOThreshold(UART5, 3);
    CF_UART_setTxFIFOThreshold(UART6, 3);
    CF_UART_setTxFIFOThreshold(UART7, 3);
    
    // Enable TX for all UARTs
    CF_UART_enableTx(UART0);
    CF_UART_enableTx(UART1);
    CF_UART_enableTx(UART2);
    CF_UART_enableTx(UART3);
    CF_UART_enableTx(UART4);
    CF_UART_enableTx(UART5);
    CF_UART_enableTx(UART6);
    CF_UART_enableTx(UART7);
    
    // Send different messages on each UART with delays between them
    // UART0: "Hello\n"
    CF_UART_writeChar(UART0, 'H');
    CF_UART_writeChar(UART0, 'e');
    CF_UART_writeChar(UART0, 'l');
    CF_UART_writeChar(UART0, 'l');
    CF_UART_writeChar(UART0, 'o');
    CF_UART_writeChar(UART0, '\n');
    
    
    // UART1: "World\n"
    CF_UART_writeChar(UART1, 'W');
    CF_UART_writeChar(UART1, 'o');
    CF_UART_writeChar(UART1, 'r');
    CF_UART_writeChar(UART1, 'l');
    CF_UART_writeChar(UART1, 'd');
    CF_UART_writeChar(UART1, '\n');
    
    
    // UART2: "Test2\n"
    CF_UART_writeChar(UART2, 'T');
    CF_UART_writeChar(UART2, 'e');
    CF_UART_writeChar(UART2, 's');
    CF_UART_writeChar(UART2, 't');
    CF_UART_writeChar(UART2, '2');
    CF_UART_writeChar(UART2, '\n');
    
    
    // UART3: "Test3\n"
    CF_UART_writeChar(UART3, 'T');
    CF_UART_writeChar(UART3, 'e');
    CF_UART_writeChar(UART3, 's');
    CF_UART_writeChar(UART3, 't');
    CF_UART_writeChar(UART3, '3');
    CF_UART_writeChar(UART3, '\n');
    
    
    // UART4: "Test4\n"
    CF_UART_writeChar(UART4, 'T');
    CF_UART_writeChar(UART4, 'e');
    CF_UART_writeChar(UART4, 's');
    CF_UART_writeChar(UART4, 't');
    CF_UART_writeChar(UART4, '4');
    CF_UART_writeChar(UART4, '\n');
    
    
    // UART5: "Test5\n"
    CF_UART_writeChar(UART5, 'T');
    CF_UART_writeChar(UART5, 'e');
    CF_UART_writeChar(UART5, 's');
    CF_UART_writeChar(UART5, 't');
    CF_UART_writeChar(UART5, '5');
    CF_UART_writeChar(UART5, '\n');
    
    
    // UART6: "Test6\n"
    CF_UART_writeChar(UART6, 'T');
    CF_UART_writeChar(UART6, 'e');
    CF_UART_writeChar(UART6, 's');
    CF_UART_writeChar(UART6, 't');
    CF_UART_writeChar(UART6, '6');
    CF_UART_writeChar(UART6, '\n');
    
    
    // UART7: "Test7\n"
    CF_UART_writeChar(UART7, 'T');
    CF_UART_writeChar(UART7, 'e');
    CF_UART_writeChar(UART7, 's');
    CF_UART_writeChar(UART7, 't');
    CF_UART_writeChar(UART7, '7');
    CF_UART_writeChar(UART7, '\n');
} 