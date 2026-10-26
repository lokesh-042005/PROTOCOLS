module uart_rx #(
    parameter integer CLK_HZ = 100000000,
    parameter integer BAUD   = 115200
) (
    input  wire       clk,
    input  wire       rst,         // Active-high asynchronous reset
    input  wire       rx,
    input  wire       parity_en,   // Must match the transmitter for this frame
    output reg  [7:0] rx_data,
    output reg        rx_valid,    // One-cycle pulse for a completed good frame
    output reg        parity_err,
    output reg        framing_err
);

    localparam integer CLKS_PER_BIT =
        (CLK_HZ + (BAUD / 2)) / BAUD;
    localparam integer HALF_BIT =
        CLKS_PER_BIT / 2;
    localparam integer COUNT_W =
        (CLKS_PER_BIT < 2) ? 1 : $clog2(CLKS_PER_BIT);

    localparam [2:0] RX_IDLE   = 3'd0,
                     RX_START  = 3'd1,
                     RX_DATA   = 3'd2,
                     RX_PARITY = 3'd3,
                     RX_STOP   = 3'd4;

    reg rx_meta;
    reg rx_sync;
    reg [2:0] state;
    reg [COUNT_W-1:0] clk_count;
    reg [2:0] bit_index;
    reg [7:0] data_reg;
    reg parity_en_reg;
    reg parity_calc;

    // Two-flop synchronizer for the asynchronous serial input.
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state        <= RX_IDLE;
            clk_count    <= 0;
            bit_index    <= 0;
            data_reg     <= 0;
            rx_data      <= 0;
            rx_valid     <= 1'b0;
            parity_err   <= 1'b0;
            framing_err  <= 1'b0;
            parity_en_reg<= 1'b0;
            parity_calc  <= 1'b0;
        end else begin
            rx_valid <= 1'b0;

            case (state)
                RX_IDLE: begin
                    clk_count <= 0;
                    bit_index <= 0;

                    if (!rx_sync) begin
                        // Capture the frame setting when the start is seen.
                        parity_en_reg <= parity_en;
                        parity_err    <= 1'b0;
                        framing_err   <= 1'b0;
                        state         <= RX_START;
                    end
                end

                RX_START: begin
                    if (clk_count == HALF_BIT - 1) begin
                        clk_count <= 0;

                        if (!rx_sync) begin
                            state <= RX_DATA;
                        end else begin
                            // A short low glitch is not a valid start bit.
                            state <= RX_IDLE;
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                RX_DATA: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        data_reg[bit_index] <= rx_sync;

                        if (bit_index == 3'd7) begin
                            parity_calc <= (^data_reg[6:0]) ^ rx_sync;
                            if (parity_en_reg)
                                state <= RX_PARITY;
                            else
                                state <= RX_STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                RX_PARITY: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count  <= 0;
                        parity_err <= (rx_sync != parity_calc);
                        state      <= RX_STOP;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                RX_STOP: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count   <= 0;
                        framing_err <= !rx_sync;

                        if (rx_sync && (!parity_en_reg ||
                                        (rx_sync && !parity_err))) begin
                            rx_data  <= data_reg;
                            rx_valid <= 1'b1;
                        end

                        state <= RX_IDLE;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                default: begin
                    state     <= RX_IDLE;
                    clk_count <= 0;
                end
            endcase
        end
    end

endmodule
