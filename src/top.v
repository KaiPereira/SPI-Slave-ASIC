// 50 MHz 

module top (
    input wire clk,
    input wire [1:0] button,
    input wire pi_mosi,
    output wire pi_miso,
    input wire pi_sclk,
    input wire pi_ce0,
    output wire [4:0] led
);

    // Little LED clock to confirm the design is working
    wire [24:0] clk_count;

    initial begin
        clk_count = 0;
    end

    always @(posedge clk) clk_count <= clk_count + 1'b1;

    always @(posedge clk_count[24]) led <= led + 1;


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
        .ui_in(),
        .uo_out(),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(), // Leave blank
        .ena(button[0]),
        .clk(clk),
        .rst_n(button[1])
    );
endmodule
