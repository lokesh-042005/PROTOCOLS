module spi_top (
    input        clk,
    input        reset,
    input        start,

    input  [7:0]  master_tx_data,
    input  [7:0]  slave_tx_data,

    output [7:0]  master_rx_data,
    output [7:0]  slave_rx_data,

    output        master_busy,
    output        master_done,
    output        slave_done
);

wire sclk;
wire mosi;
wire miso;
wire cs;


spi_master u_master (
    .clk       (clk),
    .reset     (reset),
    .start     (start),
    .tx_data   (master_tx_data),
    .miso      (miso),

    .sclk      (sclk),
    .mosi      (mosi),
    .cs        (cs),
    .rx_data   (master_rx_data),
    .busy      (master_busy),
    .done      (master_done)
);


spi_slave u_slave (
    .reset     (reset),
    .cs        (cs),
    .sclk      (sclk),
    .mosi      (mosi),
    .tx_data   (slave_tx_data),

    .miso      (miso),
    .rx_data   (slave_rx_data),
    .done       (slave_done)
);

endmodule
