module icepi_top (
    input wire clk,
    input wire [1:0] button,
    input wire pi_mosi,
    input wire pi_miso,
    input wire pi_sclk,
    input wire pi_ce0
);
    wire [7:0] uio_in;
    wire [7:0] uio_out;

    assign uio_in[0] = pi_ce0;
    assign uio_in[1] = pi_mosi;
    assign pi_miso = uio_out[2];
    assign uio_in[3] = pi_sclk;
    assign uio_in[4] = 1'b0;
    assign uio_in[5] = 1'b1;
    assign uio_in[6] = 1'b0;
    assign uio_in[7] = 1'b0;

    tt_um_kaipereira_spi_slave dut (
        .ui_in(8'b0),
        .uo_out(8'b0),
        .uio_in(uio),
        .uio_out(uio),
        .uio_oe(), // Leave blank
        .ena(button[0]),
        .clk(clk),
        .rst_n(button[1])
    )
endmodule
