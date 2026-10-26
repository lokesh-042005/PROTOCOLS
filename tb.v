`timescale 1ns/1ps

module tb_uart;

    localparam integer BAUD = 115200;

    reg tx_clk = 1'b0;
    reg rx_clk = 1'b0;
    reg rst = 1'b1;
    reg tx_start = 1'b0;
    reg [7:0] tx_data = 8'h00;
    reg parity_en = 1'b0;

    wire tx_line;
    wire tx_busy;
    wire [7:0] rx_data;
    wire rx_valid;
    wire parity_err;
    wire framing_err;

    // 50 MHz TX clock and 100 MHz RX clock.
    always #10 tx_clk = ~tx_clk;
    always #5  rx_clk = ~rx_clk;

    uart_tx #(
        .CLK_HZ(50000000),
        .BAUD(BAUD)
    ) transmitter (
        .clk(tx_clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .parity_en(parity_en),
        .tx(tx_line),
        .tx_busy(tx_busy)
    );

    uart_rx #(
        .CLK_HZ(100000000),
        .BAUD(BAUD)
    ) receiver (
        .clk(rx_clk),
        .rst(rst),
        .rx(tx_line),
        .parity_en(parity_en),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .parity_err(parity_err),
        .framing_err(framing_err)
    );

    task send_and_check;
        input [7:0] payload;
        input       use_parity;
        integer cycles;
        begin
            // Wait for the transmitter to become available.
            wait (tx_busy == 1'b0);

            @(negedge tx_clk);
            tx_data   = payload;
            parity_en = use_parity;
            tx_start  = 1'b1;

            @(negedge tx_clk);
            tx_start = 1'b0;

            // Wait up to 20,000 receiver clocks for the received frame.
            cycles = 0;
            while ((rx_valid !== 1'b1) && (cycles < 20000)) begin
                @(posedge rx_clk);
                cycles = cycles + 1;
            end

            if (rx_valid !== 1'b1) begin
                $display("FAIL: timeout waiting for payload %02h", payload);
                $fatal(1);
            end

            if (rx_data !== payload) begin
                $display("FAIL: expected %02h, received %02h",
                         payload, rx_data);
                $fatal(1);
            end

            if ((parity_err !== 1'b0) || (framing_err !== 1'b0)) begin
                $display("FAIL: parity_err=%b framing_err=%b",
                         parity_err, framing_err);
                $fatal(1);
            end

            $display("PASS: parity_en=%b data=%02h", use_parity, rx_data);

            // Allow the one-cycle rx_valid pulse to clear.
            @(negedge rx_clk);
        end
    endtask

    initial begin
      
    $dumpfile("uart_wave.vcd");
    $dumpvars(0, tb_uart);

    #200;
    rst = 1'b0;
	 #200;
        rst = 1'b0;

        repeat (10) @(posedge rx_clk);

        send_and_check(8'hA5, 1'b0);
        send_and_check(8'h3C, 1'b1);
        send_and_check(8'h00, 1'b1);
        send_and_check(8'hFF, 1'b0);

        $display("All UART checks passed.");
        $finish;
    end

    initial begin
        #1000000;
        $fatal(1, "Overall testbench timeout");
    end

endmodule
