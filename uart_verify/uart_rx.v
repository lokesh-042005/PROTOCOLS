module uart_rx(
    input clk,
    input rst,
    input rx,
    input baud16_tick,
    output reg [7:0] rx_data,
    output reg rx_done,
    output reg parity_error
);

reg [7:0] data_reg;
reg parity_reg;
reg [2:0] bit_index;
reg [2:0] state;
reg [3:0] sample_count;

localparam idle   = 3'b000,
           start  = 3'b001,
           data   = 3'b010,
           parity = 3'b011,
           stop   = 3'b100;

always @(posedge clk) begin
    if (rst) begin
        state        <= idle;
        bit_index    <= 3'd0;
        data_reg     <= 8'd0;
        parity_reg   <= 1'b0;
        rx_data      <= 8'd0;
        sample_count <= 4'd0;
        rx_done      <= 1'b0;
        parity_error <= 1'b0;
    end
    else begin
        rx_done <= 1'b0;

        case (state)

            idle: begin
                if (rx == 1'b0) begin
                    sample_count <= 4'd0;
                    parity_error <= 1'b0;
                    state        <= start;
                end
            end

            start: begin
                if (baud16_tick) begin
                    if (sample_count == 4'd7) begin
                        if (rx == 1'b0) begin
                            bit_index    <= 3'd0;
                            sample_count <= 4'd0;
                            state        <= data;
                        end
                        else begin
                            sample_count <= 4'd0;
                            state        <= idle;
                        end
                    end
                    else begin
                        sample_count <= sample_count + 1'b1;
                    end
                end
            end

            data: begin
                if (baud16_tick) begin
                    if (sample_count == 4'd15) begin
                        sample_count <= 4'd0;
                        data_reg[bit_index] <= rx;

                        if (bit_index == 3'd7) begin
                            bit_index <= 3'd0;
                            state     <= parity;
                        end
                        else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end
                    else begin
                        sample_count <= sample_count + 1'b1;
                    end
                end
            end

            parity: begin
                if (baud16_tick) begin
                    if (sample_count == 4'd15) begin
                        sample_count <= 4'd0;
                        parity_reg   <= rx;

                        if (rx != (^data_reg))
                            parity_error <= 1'b1;
                        else
                            parity_error <= 1'b0;

                        state <= stop;
                    end
                    else begin
                        sample_count <= sample_count + 1'b1;
                    end
                end
            end

            stop: begin
                if (baud16_tick) begin
                    if (sample_count == 4'd15) begin
                        sample_count <= 4'd0;

                        if (rx == 1'b1) begin
                            rx_data <= data_reg;
                            rx_done <= 1'b1;
                            bit_index <= 3'd0;
                            state <= idle;
                        end
                        else begin
                            state <= idle;
                        end
                    end
                    else begin
                        sample_count <= sample_count + 1'b1;
                    end
                end
            end

            default: begin
                state <= idle;
            end

        endcase
    end
end

endmodule
