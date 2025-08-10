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

module multi_uart_wrapper (
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

    // Logic Analyzer Signals for interrupts
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // UART pins - 8 UARTs using GPIO pins 0-15
    input [7:0] uart_rx,      // RX pins: 0,2,4,6,9,11,13,15
    output [7:0] uart_tx,     // TX pins: 1,3,5,7,10,12,14,16
    output [16:0] io_oeb,     // Output enable for all used pins
    
    // IRQ - use only 3 bits for main interrupts, LA for additional
    output [2:0] uart_irq
);

    // Wishbone address decoder for 8 UARTs
    // Each UART gets 4KB address space (12 bits)
    // UART0: 0x30000000-0x30000FFF
    // UART1: 0x30001000-0x30001FFF
    // UART2: 0x30002000-0x30002FFF
    // UART3: 0x30003000-0x30003FFF
    // UART4: 0x30004000-0x30004FFF
    // UART5: 0x30005000-0x30005FFF
    // UART6: 0x30006000-0x30006FFF
    // UART7: 0x30007000-0x30007FFF
    
    wire [2:0] uart_sel;
    wire [7:0] uart_ack;
    wire [31:0] uart_dat_o [7:0];
    wire [7:0] uart_irq_internal;
    
    // Address decoder
    // Select UART based on address bits above the 16-bit register space
    // so that intra-UART offsets (e.g. 0xFF10) don't affect selection.
    // Map UARTn at 0x300n_0000 (64KB spacing). Use bits [19:16] to select 0..7.
    assign uart_sel = wbs_adr_i[19:16];
    
    // Generate individual UART select signals
    wire [7:0] uart_stb;
    assign uart_stb[0] = (uart_sel == 3'b000) && wbs_stb_i;
    assign uart_stb[1] = (uart_sel == 3'b001) && wbs_stb_i;
    assign uart_stb[2] = (uart_sel == 3'b010) && wbs_stb_i;
    assign uart_stb[3] = (uart_sel == 3'b011) && wbs_stb_i;
    assign uart_stb[4] = (uart_sel == 3'b100) && wbs_stb_i;
    assign uart_stb[5] = (uart_sel == 3'b101) && wbs_stb_i;
    assign uart_stb[6] = (uart_sel == 3'b110) && wbs_stb_i;
    assign uart_stb[7] = (uart_sel == 3'b111) && wbs_stb_i;
    
    // Combine acknowledgments and data
    assign wbs_ack_o = |uart_ack;

    // Mux read data based on selected UART (avoid variable index on arrays)
    always @* begin
        case (uart_sel)
            3'b000: wbs_dat_o = uart_dat_o[0];
            3'b001: wbs_dat_o = uart_dat_o[1];
            3'b010: wbs_dat_o = uart_dat_o[2];
            3'b011: wbs_dat_o = uart_dat_o[3];
            3'b100: wbs_dat_o = uart_dat_o[4];
            3'b101: wbs_dat_o = uart_dat_o[5];
            3'b110: wbs_dat_o = uart_dat_o[6];
            3'b111: wbs_dat_o = uart_dat_o[7];
            default: wbs_dat_o = 32'h0;
        endcase
    end
    
    // Route interrupts: first 3 to user_irq, rest to LA
    assign uart_irq = uart_irq_internal[2:0];
    assign la_data_out[7:0] = uart_irq_internal[7:0];
    
    // GPIO pin assignments for 8 UARTs
    // UART0: RX=0, TX=1
    // UART1: RX=2, TX=3
    // UART2: RX=4, TX=5
    // UART3: RX=6, TX=7
    // UART4: RX=9, TX=10
    // UART5: RX=11, TX=12
    // UART6: RX=13, TX=14
    // UART7: RX=15, TX=16
    
    // UART0
    CF_UART_WB uart0 (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .adr_i(wbs_adr_i),
        .dat_i(wbs_dat_i),
        .dat_o(uart_dat_o[0]),
        .sel_i(wbs_sel_i),
        .cyc_i(wbs_cyc_i),
        .stb_i(uart_stb[0]),
        .ack_o(uart_ack[0]),
        .we_i(wbs_we_i),
        .IRQ(uart_irq_internal[0]),
        .rx(uart_rx[0]),
        .tx(uart_tx[0])
    );
    
    // UART1
    CF_UART_WB uart1 (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .adr_i(wbs_adr_i),
        .dat_i(wbs_dat_i),
        .dat_o(uart_dat_o[1]),
        .sel_i(wbs_sel_i),
        .cyc_i(wbs_cyc_i),
        .stb_i(uart_stb[1]),
        .ack_o(uart_ack[1]),
        .we_i(wbs_we_i),
        .IRQ(uart_irq_internal[1]),
        .rx(uart_rx[1]),
        .tx(uart_tx[1])
    );
    
    // UART2
    CF_UART_WB uart2 (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .adr_i(wbs_adr_i),
        .dat_i(wbs_dat_i),
        .dat_o(uart_dat_o[2]),
        .sel_i(wbs_sel_i),
        .cyc_i(wbs_cyc_i),
        .stb_i(uart_stb[2]),
        .ack_o(uart_ack[2]),
        .we_i(wbs_we_i),
        .IRQ(uart_irq_internal[2]),
        .rx(uart_rx[2]),
        .tx(uart_tx[2])
    );
    
    // UART3
    CF_UART_WB uart3 (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .adr_i(wbs_adr_i),
        .dat_i(wbs_dat_i),
        .dat_o(uart_dat_o[3]),
        .sel_i(wbs_sel_i),
        .cyc_i(wbs_cyc_i),
        .stb_i(uart_stb[3]),
        .ack_o(uart_ack[3]),
        .we_i(wbs_we_i),
        .IRQ(uart_irq_internal[3]),
        .rx(uart_rx[3]),
        .tx(uart_tx[3])
    );
    
    // UART4
    CF_UART_WB uart4 (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .adr_i(wbs_adr_i),
        .dat_i(wbs_dat_i),
        .dat_o(uart_dat_o[4]),
        .sel_i(wbs_sel_i),
        .cyc_i(wbs_cyc_i),
        .stb_i(uart_stb[4]),
        .ack_o(uart_ack[4]),
        .we_i(wbs_we_i),
        .IRQ(uart_irq_internal[4]),
        .rx(uart_rx[4]),
        .tx(uart_tx[4])
    );
    
    // UART5
    CF_UART_WB uart5 (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .adr_i(wbs_adr_i),
        .dat_i(wbs_dat_i),
        .dat_o(uart_dat_o[5]),
        .sel_i(wbs_sel_i),
        .cyc_i(wbs_cyc_i),
        .stb_i(uart_stb[5]),
        .ack_o(uart_ack[5]),
        .we_i(wbs_we_i),
        .IRQ(uart_irq_internal[5]),
        .rx(uart_rx[5]),
        .tx(uart_tx[5])
    );
    
    // UART6
    CF_UART_WB uart6 (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .adr_i(wbs_adr_i),
        .dat_i(wbs_dat_i),
        .dat_o(uart_dat_o[6]),
        .sel_i(wbs_sel_i),
        .cyc_i(wbs_cyc_i),
        .stb_i(uart_stb[6]),
        .ack_o(uart_ack[6]),
        .we_i(wbs_we_i),
        .IRQ(uart_irq_internal[6]),
        .rx(uart_rx[6]),
        .tx(uart_tx[6])
    );
    
    // UART7
    CF_UART_WB uart7 (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .adr_i(wbs_adr_i),
        .dat_i(wbs_dat_i),
        .dat_o(uart_dat_o[7]),
        .sel_i(wbs_sel_i),
        .cyc_i(wbs_cyc_i),
        .stb_i(uart_stb[7]),
        .ack_o(uart_ack[7]),
        .we_i(wbs_we_i),
        .IRQ(uart_irq_internal[7]),
        .rx(uart_rx[7]),
        .tx(uart_tx[7])
    );
    
    // Configure GPIO output enables
    // RX pins (0,2,4,6,9,11,13,15) are inputs (io_oeb = 1)
    // TX pins (1,3,5,7,10,12,14,16) are outputs (io_oeb = 0)
    assign io_oeb[0] = 1'b1;   // UART0 RX
    assign io_oeb[1] = 1'b0;   // UART0 TX
    assign io_oeb[2] = 1'b1;   // UART1 RX
    assign io_oeb[3] = 1'b0;   // UART1 TX
    assign io_oeb[4] = 1'b1;   // UART2 RX
    assign io_oeb[5] = 1'b0;   // UART2 TX
    assign io_oeb[6] = 1'b1;   // UART3 RX
    assign io_oeb[7] = 1'b0;   // UART3 TX
    assign io_oeb[9] = 1'b1;   // UART4 RX
    assign io_oeb[10] = 1'b0;  // UART4 TX
    assign io_oeb[11] = 1'b1;  // UART5 RX
    assign io_oeb[12] = 1'b0;  // UART5 TX
    assign io_oeb[13] = 1'b1;  // UART6 RX
    assign io_oeb[14] = 1'b0;  // UART6 TX
    assign io_oeb[15] = 1'b1;  // UART7 RX
    assign io_oeb[16] = 1'b0;  // UART7 TX
    
    // Set unused pins to input (high impedance)
    assign io_oeb[8] = 1'b1;   // Unused pin

endmodule 