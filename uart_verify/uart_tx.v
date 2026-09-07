module uart_tx(
    input clk,
    input rst,
    input baud16_tick,
    input tx_start,
    input [7:0] tx_data,
    output reg tx,
    output reg tx_busy
);

reg [2:0] bit_index;
reg [7:0] data_reg;
reg parity_reg;
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
        tx           <= 1'b1;
        tx_busy      <= 1'b0;
        data_reg     <= 8'd0;
        parity_reg   <= 1'b0;
        bit_index    <= 3'd0;
        sample_count <= 4'd0;
    end
    else begin
        case (state)

            idle: begin
                tx      <= 1'b1;
                tx_busy <= 1'b0;

                if (tx_start) begin
                    data_reg     <= tx_data;
                    parity_reg   <= ^tx_data;
                    bit_index    <= 3'd0;
                    sample_count <= 4'd0;
                    tx_busy      <= 1'b1;
                    state        <= start;
                end
            end

            start: begin
                tx      <= 1'b0;
                tx_busy <= 1'b1;

                if (baud16_tick) begin
                    if (sample_count == 4'd15) begin
                        sample_count <= 4'd0;
                        state        <= data;
                    end
                    else begin
                        sample_count <= sample_count + 1'b1;
                    end
                end
            end

            data: begin
                tx      <= data_reg[bit_index];
                tx_busy <= 1'b1;

                if (baud16_tick) begin
                    if (sample_count == 4'd15) begin
                        sample_count <= 4'd0;

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
                tx      <= parity_reg;
                tx_busy <= 1'b1;

                if (baud16_tick) begin
                    if (sample_count == 4'd15) begin
                        sample_count <= 4'd0;
                        state        <= stop;
                    end
                    else begin
                        sample_count <= sample_count + 1'b1;
                    end
                end
            end

            stop: begin
                tx      <= 1'b1;
                tx_busy <= 1'b1;

                if (baud16_tick) begin
                    if (sample_count == 4'd15) begin
                        sample_count <= 4'd0;
                        state        <= idle;
                    end
                    else begin
                        sample_count <= sample_count + 1'b1;
                    end
                end
            end

            default: begin
                state        <= idle;
                tx           <= 1'b1;
                tx_busy      <= 1'b0;
                bit_index    <= 3'd0;
                sample_count <= 4'd0;
            end

        endcase
    end
end

endmodule
