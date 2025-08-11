// Copyright 2025 ChipFoundry, a DBA of Umbralogic Technologies LLC
// SPDX-License-Identifier: Apache-2.0

#include <firmware_apis.h>
#include <CF_SPI.h>
#include <CF_SPI.c>

// SPI base addresses (64KB stride), SPI block pages at 0x3008_0000 .. 0x300C_0000
#define SPI0_BASE 0x30080000
#define SPI1_BASE 0x30090000
#define SPI2_BASE 0x300A0000
#define SPI3_BASE 0x300B0000
#define SPI4_BASE 0x300C0000

// Driver uses base addresses directly (uint32_t)

void main() {
    ManagmentGpio_outputEnable();
    ManagmentGpio_write(0);
    enableHkSpi(0);

    // Configure SPI GPIOs
    // SPI0: MISO=17 (in), MOSI=18 (out), SCLK=19 (out), CSB=20 (out)
    GPIOs_configure(17, GPIO_MODE_USER_STD_INPUT_PULLUP);
    GPIOs_configure(18, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(19, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(20, GPIO_MODE_USER_STD_OUTPUT);
    // SPI1
    GPIOs_configure(21, GPIO_MODE_USER_STD_INPUT_PULLUP);
    GPIOs_configure(22, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(23, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(24, GPIO_MODE_USER_STD_OUTPUT);
    // SPI2
    GPIOs_configure(25, GPIO_MODE_USER_STD_INPUT_PULLUP);
    GPIOs_configure(26, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(27, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(28, GPIO_MODE_USER_STD_OUTPUT);
    // SPI3
    GPIOs_configure(29, GPIO_MODE_USER_STD_INPUT_PULLUP);
    GPIOs_configure(30, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(31, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(32, GPIO_MODE_USER_STD_OUTPUT);
    // SPI4
    GPIOs_configure(33, GPIO_MODE_USER_STD_INPUT_PULLUP);
    GPIOs_configure(34, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(35, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(36, GPIO_MODE_USER_STD_OUTPUT);

    GPIOs_loadConfigs();
    User_enableIF();

    // Indicate FW ready
    ManagmentGpio_write(1);

    // Enable GCLK for all SPIs, set simple config: CPOL=0, CPHA=0, set PR to 0x40
    uint32_t spis[5] = {SPI0_BASE, SPI1_BASE, SPI2_BASE, SPI3_BASE, SPI4_BASE};
    for (int i = 0; i < 5; ++i) {
        CF_SPI_setGclkEnable(spis[i], 1);
        CF_SPI_writepolarity(spis[i], 0);
        CF_SPI_writePhase(spis[i], 0);
        CF_SPI_setPrescaler(spis[i], 0x40u);
    }

    // For each SPI, assert CSB, keep ENABLE high while BUSY is high, send one byte, then deassert
    for (int i = 0; i < 5; ++i) {
        unsigned byte = 0xA0u + (unsigned)i;
        CF_SPI_assertCs(spis[i]);
        CF_SPI_enable(spis[i]);
        CF_SPI_writeData(spis[i], (int)byte);
        CF_SPI_waitNotBusy(spis[i]);
        CF_SPI_disable(spis[i]);
        CF_SPI_deassertCs(spis[i]);
    }
}


