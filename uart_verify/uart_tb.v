module uart_tb;
reg clk;
reg rst;
wire uart_rx;
wire uart_tx;
//transmitter
reg [7:0] tx_data;
reg tx_start;
reg parity_en;
reg parity_type;
wire tx_busy;
//receiver
wire [7:0]rx_data;
wire rx_valid;
wire rx_error;

uart u1(.clk(clk),
	.rst(rst),
	.uart_tx(uart_tx),
	.uart_rx(uart_rx),
	.tx_data(tx_data),
	.tx_start(tx_start),
	.parity_en(parity_en),
    .parity_type(parity_type),
	.tx_busy(tx_busy),
	.rx_data(rx_data),
	.rx_valid(rx_valid),
	.rx_error(rx_error));
	
initial begin
	clk = 0;
	forever #10clk = ~clk;
end
assign uart_rx = uart_tx;

initial begin
	rst = 1; 
	tx_data = 8'h64; 
	tx_start = 0; 
	parity_en = 1;
	parity_type = 1;
	#100;
	
	rst = 0;
	#50;
	tx_start = 1; 
	#50; 
	tx_start = 0; 
	#50;
	#2000000;
	
    $finish;
end 


initial begin 
	        $monitor("time=%0t, parity_en=%0d, parity_type=%0d, tx_start=%0d, tx_data=%0d, tx_busy=%0d, uart_tx=%0d, uart_rx=%0d, rx_data=%0d, rx_valid=%0d, rx_error=%0d", $time, parity_en, parity_type, tx_start, tx_data, tx_busy, uart_tx, uart_rx, rx_data, rx_valid, rx_error);
end
initial begin
    $dumpfile("uart_wave.vcd");
    $dumpvars(0, uart_tb);
end

endmodule
