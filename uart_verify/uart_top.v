module uart #(parameter integer clock = 50000000,baudrate = 115200)
(input clk,
input rst,
input uart_rx,
output uart_tx,
//transmitter
input [7:0] tx_data,
input tx_start,
input parity_en,
input parity_type,
output tx_busy,
//receiver
output [7:0]rx_data,
output rx_valid,
output rx_error);

wire tx_internal;


transmiter #(.clock(clock),
	      .baudrate(baudrate))
uart_tx1(.clk(clk),
	 .rst(rst),
	 .tx_data(tx_data),
	 .tx_start(tx_start),
	 .parity_en(parity_en),
     .parity_type(parity_type),
	 .tx(tx_internal),
	 .tx_busy(tx_busy));
	
receiver #(.clock(clock),
	   .baudrate(baudrate))
uart_rx1(.clk(clk),
	 .rst(rst),
	 .rx(uart_rx),
     .parity_en(parity_en),
     .parity_type(parity_type),
	 .rx_data(rx_data),
	 .rx_valid(rx_valid),
	 .rx_error(rx_error));

assign uart_tx = tx_internal;

endmodule
