![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# SPI Slave Device

This is my custom SPI slave ASIC I've decided to make in order to learn how to make my own chip from start to end.

It simply receives the MOSI signal from the master controller and then just re-sends it over MISO but it was surprisingly challenging for me to make because it's my first Verilog project, but it was so much fun!

## How the slave works

My SPI slave is quite simple... 

First, I use a triple flip-flop synchronizer to align the external SCLK clock domain, with the internal CLK clock domain and to also prevent metastability.

Next, I use the internal CLK domain to sample the falling and rising edges of the synchronized SCLK domain and then I shift a full byte of MOSI into a byte buffer on the rising edges, and then once that's complete, I'll shift it out onto MISO on the falling edges.

## Test Bench

My test bench isn't great, but provides a proof of concept. I generate the internal slave's CLK domain with a frequency of 16 MHz, and then I generate a 1 MHz serial clock that I've simulated coming from an asynchronous master device by offsetting it from the slave's CLK domain.

Based off of the serial clock, I send a send a byte with a 1/4 clock cycle buffer on the rising and falling edge on MOSI which is echoed back over MISO by the slave ASIC.

## Setup

Setting up the project is quite simple; I'd suggest installing the ![OSS CAD Suite environment](https://github.com/yosyshq/oss-cad-suite-build) which is a binary software distribution with all the tools you need to run the project, and then you can visualize the waveforms by running the GTKWave viewer:

```
cd src/test
make -B
gtkwave tb.fst tb.gtkw
```

## Programming Configuration

I've also added all the necessary files to configure my ASIC design onto the Icepi Zero, the FPGA board I use. If you want to program a different board, replace the .lpf with your own FPGA's LPF, modify the top file for your device, and then just run `make`. 

## Inspiration

This project uses the tinytapeout template which has all of the workflows to build your project and get it ready for manufacturing which I'll eventually do with some future projects!

Thanks to [Julia Desmazes](https://essenceia.github.io/about/) for bringing me into this amazing world :D 
