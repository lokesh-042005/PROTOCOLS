module uart_tb;

reg clk;
reg rst;
reg tx_start;
reg [7:0] tx_data;

wire tx;
wire tx_busy;
wire rx;
wire [7:0] rx_data;
wire rx_done;
wire parity_error;

assign rx = tx;

uart_top #(
    .clk_freq(50000000),
    .baud(9600)
)
uut (
    .clk(clk),
    .rst(rst),
    .tx_start(tx_start),
    .tx_data(tx_data),
    .tx(tx),
    .tx_busy(tx_busy),
    .rx(rx),
    .rx_data(rx_data),
    .rx_done(rx_done),
    .parity_error(parity_error)
);

initial clk = 1'b0;

always #10 clk = ~clk;

initial begin

    $dumpfile("wave.vcd");
    $dumpvars(0, uart_tb);

    rst = 1'b1;
    tx_start = 1'b0;
    tx_data = 8'h00;

    #20;

    rst = 1'b0;

    wait(!tx_busy);

    @(posedge clk);
    tx_data = 8'h55;
    tx_start = 1'b1;

    @(posedge clk);
    tx_start = 1'b0;

    wait(rx_done);

    $display("TX DATA = %h", 8'h55);
    $display("RX DATA = %h", rx_data);
    $display("PARITY ERROR = %b", parity_error);

    if ((rx_data == 8'h55) && (parity_error == 1'b0))
        $display("BYTE 1 PASS");
    else
        $display("BYTE 1 FAIL");

    wait(!tx_busy);

    @(posedge clk);
    tx_data = 8'hA3;
    tx_start = 1'b1;

    @(posedge clk);
    tx_start = 1'b0;

    wait(rx_done);

    $display("TX DATA = %h", 8'hA3);
    $display("RX DATA = %h", rx_data);
    $display("PARITY ERROR = %b", parity_error);

    if ((rx_data == 8'hA3) && (parity_error == 1'b0))
        $display("BYTE 2 PASS");
    else
        $display("BYTE 2 FAIL");

    wait(!tx_busy);

    @(posedge clk);
    tx_data = 8'hF0;
    tx_start = 1'b1;

    @(posedge clk);
    tx_start = 1'b0;

    wait(rx_done);

    $display("TX DATA = %h", 8'hF0);
    $display("RX DATA = %h", rx_data);
    $display("PARITY ERROR = %b", parity_error);

    if ((rx_data == 8'hF0) && (parity_error == 1'b0))
        $display("BYTE 3 PASS");
    else
        $display("BYTE 3 FAIL");

    #100000;

    $finish;

end

endmodule
