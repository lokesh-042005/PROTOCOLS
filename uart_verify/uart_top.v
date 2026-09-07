module uart_top #(
    parameter clk_freq = 50000000,
    parameter baud = 9600
)(
    input clk,
    input rst,
    input tx_start,
    input [7:0] tx_data,
    output tx,
    output tx_busy,
    input rx,
    output [7:0] rx_data,
    output rx_done,
    output parity_error
);

wire baud16_tick;

baud_rate_generator #(
    .clk_freq(clk_freq),
    .baud(baud)
)
baud_gen (
    .clk(clk),
    .rst(rst),
    .baud16_tick(baud16_tick)
);

uart_tx tx_inst (
    .clk(clk),
    .rst(rst),
    .baud16_tick(baud16_tick),
    .tx_start(tx_start),
    .tx_data(tx_data),
    .tx(tx),
    .tx_busy(tx_busy)
);

uart_rx rx_inst (
    .clk(clk),
    .rst(rst),
    .rx(rx),
    .baud16_tick(baud16_tick),
    .rx_data(rx_data),
    .rx_done(rx_done),
    .parity_error(parity_error)
);

endmodule
