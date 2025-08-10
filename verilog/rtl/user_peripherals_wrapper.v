// SPDX-FileCopyrightText: 2024 ChipFoundry
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

// This is the actual user project logic wrapper that aggregates peripherals.
// The top-level user_project_wrapper should only instantiate this module.
module user_peripherals_wrapper (
`ifdef USE_POWER_PINS
    inout vdda1,
    inout vdda2,
    inout vssa1,
    inout vssa2,
    inout vccd1,
    inout vccd2,
    inout vssd1,
    inout vssd2,
`endif
    // Wishbone
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic analyzer
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] user_irq
);

    // Wishbone block select within 0x3000_0000 user window:
    // UART pages: 0x3000_0000 .. 0x3007_FFFF  (A[19:16] = 0..7)
    // SPI  pages: 0x3008_0000 .. 0x300C_FFFF (A[19:16] = 8..12)
    wire [3:0] page_sel = wbs_adr_i[19:16];
    wire is_uart_block = (page_sel <= 4'd7);
    wire is_spi_block  = (page_sel >= 4'd8) && (page_sel <= 4'd12);

    // UART sub-bus
    wire        wbs_ack_uart;
    wire [31:0] wbs_dat_uart;

    // SPI sub-bus
    wire        wbs_ack_spi;
    wire [31:0] wbs_dat_spi;

    // Combine Wishbone responses
    assign wbs_ack_o = wbs_ack_uart | wbs_ack_spi;
    assign wbs_dat_o = is_uart_block ? wbs_dat_uart :
                       is_spi_block  ? wbs_dat_spi  : 32'h0;

    // UART wiring
    wire [7:0] uart_rx_bus;
    wire [7:0] uart_tx_bus;
    wire [16:0] uart_io_oeb;
    wire [7:0]  uart_irq_internal;

    assign uart_rx_bus = { io_in[15], io_in[13], io_in[11], io_in[9],
                           io_in[6],  io_in[4],  io_in[2],  io_in[0] };

    multi_uart_wrapper u_multi_uart (
`ifdef USE_POWER_PINS
        .vccd1(vccd1),
        .vssd1(vssd1),
`endif
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stb_i & is_uart_block),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ack_uart),
        .wbs_dat_o(wbs_dat_uart),
        .la_data_in(la_data_in),
        .la_data_out(la_data_out),
        .la_oenb(la_oenb),
        .uart_rx(uart_rx_bus),
        .uart_tx(uart_tx_bus),
        .io_oeb(uart_io_oeb),
        .uart_irq(user_irq)
    );

    // Map UART TX to IOs
    assign io_out[1]  = uart_tx_bus[0];
    assign io_out[3]  = uart_tx_bus[1];
    assign io_out[5]  = uart_tx_bus[2];
    assign io_out[7]  = uart_tx_bus[3];
    assign io_out[10] = uart_tx_bus[4];
    assign io_out[12] = uart_tx_bus[5];
    assign io_out[14] = uart_tx_bus[6];
    assign io_out[16] = uart_tx_bus[7];

    // Map UART OEBs to IOs [0..16]
    assign io_oeb[16:0] = uart_io_oeb[16:0];

    // SPI wiring: 5 instances
    wire [4:0] spi_miso_bus;
    wire [4:0] spi_mosi_bus;
    wire [4:0] spi_sclk_bus;
    wire [4:0] spi_csb_bus;
    wire [4:0] spi_irq_bus;

    // Map IOs to SPI buses
    assign spi_miso_bus[0] = io_in[17];
    assign spi_miso_bus[1] = io_in[21];
    assign spi_miso_bus[2] = io_in[25];
    assign spi_miso_bus[3] = io_in[29];
    assign spi_miso_bus[4] = io_in[33];

    multi_spi_wrapper u_multi_spi (
`ifdef USE_POWER_PINS
        .vccd1(vccd1),
        .vssd1(vssd1),
`endif
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stb_i & is_spi_block),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ack_spi),
        .wbs_dat_o(wbs_dat_spi),
        .spi_miso(spi_miso_bus),
        .spi_mosi(spi_mosi_bus),
        .spi_sclk(spi_sclk_bus),
        .spi_csb(spi_csb_bus),
        .spi_irq(spi_irq_bus)
    );

    // Drive SPI IOs from buses
    // SPI0 pins
    assign io_out[18] = spi_mosi_bus[0];
    assign io_out[19] = spi_sclk_bus[0];
    assign io_out[20] = spi_csb_bus[0];
    // SPI1 pins
    assign io_out[22] = spi_mosi_bus[1];
    assign io_out[23] = spi_sclk_bus[1];
    assign io_out[24] = spi_csb_bus[1];
    // SPI2 pins
    assign io_out[26] = spi_mosi_bus[2];
    assign io_out[27] = spi_sclk_bus[2];
    assign io_out[28] = spi_csb_bus[2];
    // SPI3 pins
    assign io_out[30] = spi_mosi_bus[3];
    assign io_out[31] = spi_sclk_bus[3];
    assign io_out[32] = spi_csb_bus[3];
    // SPI4 pins
    assign io_out[34] = spi_mosi_bus[4];
    assign io_out[35] = spi_sclk_bus[4];
    assign io_out[36] = spi_csb_bus[4];

    // Configure OEB for SPI pins: MISO inputs, others outputs
    assign io_oeb[17] = 1'b1; assign io_oeb[18] = 1'b0; assign io_oeb[19] = 1'b0; assign io_oeb[20] = 1'b0;
    assign io_oeb[21] = 1'b1; assign io_oeb[22] = 1'b0; assign io_oeb[23] = 1'b0; assign io_oeb[24] = 1'b0;
    assign io_oeb[25] = 1'b1; assign io_oeb[26] = 1'b0; assign io_oeb[27] = 1'b0; assign io_oeb[28] = 1'b0;
    assign io_oeb[29] = 1'b1; assign io_oeb[30] = 1'b0; assign io_oeb[31] = 1'b0; assign io_oeb[32] = 1'b0;
    assign io_oeb[33] = 1'b1; assign io_oeb[34] = 1'b0; assign io_oeb[35] = 1'b0; assign io_oeb[36] = 1'b0;

    // Default unused IO outputs low and inputs hi-Z by default; rely on caravel defaults for others

endmodule

`default_nettype wire


