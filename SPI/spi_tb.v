`timescale 1ns/1ps

module spi_tb;

reg clk;
reg reset;
reg start;

reg [7:0] master_tx_data;
reg [7:0] slave_tx_data;

wire [7:0] master_rx_data;
wire [7:0] slave_rx_data;

wire master_busy;
wire master_done;
wire slave_done;


spi_top uut (
    .clk            (clk),
    .reset          (reset),
    .start          (start),
    .master_tx_data (master_tx_data),
    .slave_tx_data  (slave_tx_data),
    .master_rx_data (master_rx_data),
    .slave_rx_data  (slave_rx_data),
    .master_busy    (master_busy),
    .master_done    (master_done),
    .slave_done     (slave_done)
);


always #5 clk = ~clk;


initial begin

    clk = 0;
    reset = 1;
    start = 0;
    master_tx_data = 8'h00;
    slave_tx_data = 8'h00;

    #20;

    reset = 0;

    master_tx_data = 8'hA5;
    slave_tx_data  = 8'h3C;

    #10;

    start = 1;

    #10;

    start = 0;

    wait(master_done);

    #20;

    $display("--------------------------------");
    $display("SPI TRANSFER");
    $display("--------------------------------");
    $display("MASTER TX = %h", master_tx_data);
    $display("SLAVE  TX = %h", slave_tx_data);
    $display("MASTER RX = %h", master_rx_data);
    $display("SLAVE  RX = %h", slave_rx_data);
    $display("--------------------------------");


    if (master_rx_data == slave_tx_data)
        $display("MASTER RECEIVE PASS");
    else
        $display("MASTER RECEIVE FAIL");


    if (slave_rx_data == master_tx_data)
        $display("SLAVE RECEIVE PASS");
    else
        $display("SLAVE RECEIVE FAIL");

    $display("--------------------------------");

    #20;

    $finish;

end


initial begin
    $dumpfile("spi.vcd");
    $dumpvars(0, spi_tb);
end

endmodule
