# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer, FallingEdge, RisingEdge, ValueChange

clk_ns = 62.5
sclk_ns = 1000 

async def sclk_clock(dut, pin, cs_pin, period_ns):
    while True:
        while (int(dut.uio_in.value) >> cs_pin) & 1:
            await ValueChange(dut.uio_in);
        
        while not ((int(dut.uio_in.value) >> cs_pin) & 1):
            dut.uio_in.value = int(dut.uio_in.value) | (1 << pin);
            await Timer(period_ns / 2, unit="ns");
            dut.uio_in.value = int(dut.uio_in.value) & ~(1 << pin);
            await Timer(period_ns / 2, unit="ns");

async def get_edge(dut, bit, rising: bool):
    prev_bit = (int(dut.uio_in.value) >> bit) & 1;

    while True:
        # Wait for the value to change
        await ValueChange(dut.uio_in);

        # Sample it after the change
        current_bit = (int(dut.uio_in.value) >> bit) & 1;

        # Check if it rose or fell
        if ((prev_bit < current_bit) and rising):
            return;
        elif ((prev_bit > current_bit) and not rising):
            return;

        # Set the initial bit to the current bit for the next sample
        prev_bit = current_bit;

async def send_byte(dut, byte, period_ns):
    first_bit = (byte >> 7) & 1;

    # Send the first bit immediately with SCLK (in it's own function)
    value = int(dut.uio_in.value)

    if first_bit:
        value |= (1 << 1)
    else:
        value &= ~(1 << 1)

    dut.uio_in.value = value # Set the MOSI bit

    # Put CS low
    value &= ~(1 << 0)
    dut.uio_in.value = value

    for i in range(8):
        # Wait for the rising edge of the serial clock
        await get_edge(dut, 3, True)

        if i == 7:
            break;

        await get_edge(dut, 3, False)

        # Shift the bit and mask out everything except the last bit and send it in the right order (we've already shifted out the first bit)
        bit = (byte >> (6 - i)) & 1

        value = int(dut.uio_in.value)

        if bit:
            value |= (1 << 1)
        else:
            value &= ~(1 << 1)

        dut.uio_in.value = value

    # Wait for the falling edge of the last serial clock to set CS high, and MOSI low
    await get_edge(dut, 3, False)

    value = int(dut.uio_in.value)
    value |= (1 << 0)
    value &= ~(1 << 1)

    dut.uio_in.value = value

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 0.0625 us (16 MHz)
    clock = Clock(dut.clk, clk_ns, unit="ns")

    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    dut.uio_in.value = int(dut.uio_in.value) | (1 << 5); # Set the 5th bit high
    dut.uio_in.value = (1 << 0) | (1 << 5)

    # Phase offset to simulate the serial clock delay from the master controller
    await Timer(67, units="ns")
    cocotb.start_soon(sclk_clock(dut, 3, 0, sclk_ns));

    # Start sending data from the master device after 10 clock cycles just to simulate something random
    await ClockCycles(dut.clk, 10)
    cocotb.start_soon(send_byte(dut, 0xBB, sclk_ns))

    await ClockCycles(dut.clk, 300)
    cocotb.start_soon(send_byte(dut, 0xBB, sclk_ns))

    await ClockCycles(dut.clk, 300)
    cocotb.start_soon(send_byte(dut, 0xBB, sclk_ns))

    dut._log.info("Test project behavior")

    # Wait for many clock cycle to see the output values
    await ClockCycles(dut.clk, 400)

    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    # assert dut.uo_out.value == 50

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.
