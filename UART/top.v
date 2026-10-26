module uart_device #(
    parameter integer TX_CLK_HZ = 50000000,
    parameter integer RX_CLK_HZ = 100000000,
    parameter integer BAUD      = 115200
) (
    input  wire       tx_clk,
    input  wire       rx_clk,
    input  wire       rst,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    input  wire       parity_en,
    input  wire       serial_rx,
    output wire       serial_tx,
    output wire       tx_busy,
    output wire [7:0] rx_data,
    output wire       rx_valid,
    output wire       parity_err,
    output wire       framing_err
);

    uart_tx #(
        .CLK_HZ(TX_CLK_HZ),
        .BAUD(BAUD)
    ) tx_inst (
        .clk(tx_clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .parity_en(parity_en),
        .tx(serial_tx),
        .tx_busy(tx_busy)
    );

    uart_rx #(
        .CLK_HZ(RX_CLK_HZ),
        .BAUD(BAUD)
    ) rx_inst (
        .clk(rx_clk),
        .rst(rst),
        .rx(serial_rx),
        .parity_en(parity_en),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .parity_err(parity_err),
        .framing_err(framing_err)
    );

endmodule
