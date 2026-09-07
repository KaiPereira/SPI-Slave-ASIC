module icepi_top (
    input wire clk,
    input wire [1:0] buttons,
    input wire pi_mosi,
    input wire pi_miso,
    input wire pi_sclk,
    input wire pi_ce0
);
    wire [7:0] uo_out;
    wire [7:0] uio; // Tricky because both uio_in and uio_out


    tt_um_kaipereira_spi_slave dut (
        ui_in(8'b0),
        uo_out(),
        uio_in(),
        uio_out(),
        uio_oe(),
        ena(),
        clk(),
        rst_n()
    )
endmodule
