module spi_slave (
    input        reset,
    input        cs,
    input        sclk,
    input        mosi,
    input  [7:0] tx_data,

    output       miso,
    output reg [7:0] rx_data,
    output reg   done
);

reg [7:0] rx_shift;
reg [3:0] rx_count;

reg [3:0] tx_count;


/* RECEIVE MOSI */

always @(posedge sclk or posedge reset) begin

    if (reset) begin
        rx_shift <= 8'h00;
        rx_data  <= 8'h00;
        rx_count <= 4'd0;
        done     <= 1'b0;
    end

    else if (!cs) begin

        rx_shift <= {rx_shift[6:0], mosi};

        if (rx_count == 4'd7) begin

            rx_data <= {rx_shift[6:0], mosi};
            rx_count <= 4'd0;
            done <= 1'b1;

        end

        else begin

            rx_count <= rx_count + 1'b1;
            done <= 1'b0;

        end
    end

    else begin
        done <= 1'b0;
    end

end


/* TRANSMIT COUNTER */

always @(negedge sclk or posedge reset) begin

    if (reset) begin
        tx_count <= 4'd0;
    end

    else if (!cs) begin

        if (tx_count == 4'd7)
            tx_count <= 4'd0;
        else
            tx_count <= tx_count + 1'b1;

    end

    else begin
        tx_count <= 4'd0;
    end

end


/* MISO */

assign miso = (!cs) ? tx_data[7 - tx_count] : 1'b0;

endmodule
