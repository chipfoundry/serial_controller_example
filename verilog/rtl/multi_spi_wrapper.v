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

module multi_spi_wrapper (
`ifdef USE_POWER_PINS
    inout vccd1,    // User area 1 1.8V supply
    inout vssd1,    // User area 1 digital ground
`endif

    // Wishbone Slave ports
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output reg [31:0] wbs_dat_o,

    // SPI pins - 5 SPI instances
    input  [4:0] spi_miso,
    output [4:0] spi_mosi,
    output [4:0] spi_sclk,
    output [4:0] spi_csb,

    // IRQs (optional)
    output [4:0] spi_irq
);

    // Address decoder for 5 SPI instances
    // Each SPI gets 64KB address space: map to pages 8..12 within user window
    wire [3:0] spi_page = wbs_adr_i[19:16];
    wire [2:0] spi_sel = (spi_page >= 4'd8) ? (spi_page - 4'd8) : 3'd0;

    wire [4:0] spi_stb;
    assign spi_stb[0] = (spi_sel == 3'd0) && wbs_stb_i;
    assign spi_stb[1] = (spi_sel == 3'd1) && wbs_stb_i;
    assign spi_stb[2] = (spi_sel == 3'd2) && wbs_stb_i;
    assign spi_stb[3] = (spi_sel == 3'd3) && wbs_stb_i;
    assign spi_stb[4] = (spi_sel == 3'd4) && wbs_stb_i;

    wire [4:0] spi_ack;
    wire [31:0] spi_dat_o [4:0];

    assign wbs_ack_o = |spi_ack;

    always @* begin
        case (spi_sel)
            3'd0: wbs_dat_o = spi_dat_o[0];
            3'd1: wbs_dat_o = spi_dat_o[1];
            3'd2: wbs_dat_o = spi_dat_o[2];
            3'd3: wbs_dat_o = spi_dat_o[3];
            3'd4: wbs_dat_o = spi_dat_o[4];
            default: wbs_dat_o = 32'h0;
        endcase
    end

    // SPI0
    CF_SPI_WB spi0 (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .adr_i(wbs_adr_i),
        .dat_i(wbs_dat_i),
        .dat_o(spi_dat_o[0]),
        .sel_i(wbs_sel_i),
        .cyc_i(wbs_cyc_i),
        .stb_i(spi_stb[0]),
        .ack_o(spi_ack[0]),
        .we_i(wbs_we_i),
        .IRQ(spi_irq[0]),
        .miso(spi_miso[0]),
        .mosi(spi_mosi[0]),
        .csb(spi_csb[0]),
        .sclk(spi_sclk[0])
    );

    // SPI1
    CF_SPI_WB spi1 (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .adr_i(wbs_adr_i),
        .dat_i(wbs_dat_i),
        .dat_o(spi_dat_o[1]),
        .sel_i(wbs_sel_i),
        .cyc_i(wbs_cyc_i),
        .stb_i(spi_stb[1]),
        .ack_o(spi_ack[1]),
        .we_i(wbs_we_i),
        .IRQ(spi_irq[1]),
        .miso(spi_miso[1]),
        .mosi(spi_mosi[1]),
        .csb(spi_csb[1]),
        .sclk(spi_sclk[1])
    );

    // SPI2
    CF_SPI_WB spi2 (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .adr_i(wbs_adr_i),
        .dat_i(wbs_dat_i),
        .dat_o(spi_dat_o[2]),
        .sel_i(wbs_sel_i),
        .cyc_i(wbs_cyc_i),
        .stb_i(spi_stb[2]),
        .ack_o(spi_ack[2]),
        .we_i(wbs_we_i),
        .IRQ(spi_irq[2]),
        .miso(spi_miso[2]),
        .mosi(spi_mosi[2]),
        .csb(spi_csb[2]),
        .sclk(spi_sclk[2])
    );

    // SPI3
    CF_SPI_WB spi3 (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .adr_i(wbs_adr_i),
        .dat_i(wbs_dat_i),
        .dat_o(spi_dat_o[3]),
        .sel_i(wbs_sel_i),
        .cyc_i(wbs_cyc_i),
        .stb_i(spi_stb[3]),
        .ack_o(spi_ack[3]),
        .we_i(wbs_we_i),
        .IRQ(spi_irq[3]),
        .miso(spi_miso[3]),
        .mosi(spi_mosi[3]),
        .csb(spi_csb[3]),
        .sclk(spi_sclk[3])
    );

    // SPI4
    CF_SPI_WB spi4 (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .adr_i(wbs_adr_i),
        .dat_i(wbs_dat_i),
        .dat_o(spi_dat_o[4]),
        .sel_i(wbs_sel_i),
        .cyc_i(wbs_cyc_i),
        .stb_i(spi_stb[4]),
        .ack_o(spi_ack[4]),
        .we_i(wbs_we_i),
        .IRQ(spi_irq[4]),
        .miso(spi_miso[4]),
        .mosi(spi_mosi[4]),
        .csb(spi_csb[4]),
        .sclk(spi_sclk[4])
    );

endmodule

`default_nettype wire


