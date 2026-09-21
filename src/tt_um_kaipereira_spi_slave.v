/*
 * Copyright (c) 2026 Kai Pereira
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_kaipereira_spi_slave (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock input  wire       
    input  wire       rst_n     // reset_n - low to reset
);

  wire spi_cs_n; // _n postfixes to denote an active-low signal because the microcontroller wants to communicate when it's low
  wire spi_sclk; // This is the clock signal coming from the master
  wire spi_miso; // Master in, slave out
  wire spi_mosi; // Master out, slave in
  wire reset; // Reset signal
  wire write_protect; // Prevent accidental writes by pulling low
  wire hold; // Pause communication without CS important so you don't stop the master clock or deselect the slave

  assign uio_oe[7:0] = 8'b0000_0100;

  assign spi_cs_n = uio_in[0];
  assign spi_mosi = uio_in[1];
  assign uio_out[2] = spi_miso;
  assign spi_sclk = uio_in[3];
  // Not using uio_in[4], matching tinytapeout SPI pinout
  assign reset = uio_in[5];
  assign write_protect = uio_in[6];
  assign hold = uio_in[7];

  // Shift registers for the stable SCLK and CS signals
  reg [2:0] sclk_reg;
  reg [1:0] cs_reg;
  reg [1:0] mosi_reg;

  // Sample on each clock edge or whenever RST changes
  // Implement CPOL and CPHA still
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin // if there's a reset, put everything into it's known state
      sclk_reg <= 3'b000;
      cs_reg <= 2'b11;
      mosi_reg <= 2'b00;
    end else begin
      sclk_reg <= {sclk_reg[1:0], spi_sclk}; // Hold another bit to get the state of the last cycle for the rising/falling edge detector
      cs_reg <= {cs_reg[0], spi_cs_n};
      mosi_reg <= {mosi_reg[0], spi_mosi};
    end
  end

  // Detect the falling or rising edge of the signal
  // Shift the falling or rising edge low after one cycle of CLK
  // Check if falling/rising is high, and sample/send if it is
  // If falling/rising is low, don't sample/send
  wire rising_edge = sclk_reg[1] & ~sclk_reg[2]; 
  wire falling_edge = ~sclk_reg[1] & sclk_reg[2];

  reg [7:0] tx_byte;
  reg [7:0] rx_byte;
  reg [2:0] count;

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      count <= 3'b0;
      tx_byte <= 8'b0;
      rx_byte <= 8'b0;
    end else if (!reset) begin
      count <= 3'b0;
      tx_byte <= 8'b0;
      rx_byte <= 8'b0;
    end else begin
      if (rising_edge & !cs_reg[0]) begin
        // Shift MOSI into the byte buffer
        rx_byte <= {rx_byte[6:0], mosi_reg[1]};

        // Update the count
        count <= count + 3'b1;

        if (count == 3'd7) begin
          count <= 3'b000;
        end
      end else if (falling_edge) begin
        // Wait for the whole byte to transfer
        // Then shift RX into TX
        if (count == 3'b000) begin
          // Load in the byte if it isn't in there yet
          tx_byte <= rx_byte;
        end else begin
          // Slowly shift the bit out
          tx_byte <= {tx_byte[6:0], 1'b0};
        end
      end
    end
  end

  // Send the current bit that's actively getting shifted
  assign spi_miso = cs_reg[0] ? 1'b0 : tx_byte[7];

  // Pull floating outputs low
  assign uio_out[1:0] = 2'b0;
  assign uio_out[7:3] = 5'b0;
  assign uo_out[7:0] = 8'b0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, 1'b0};

endmodule
