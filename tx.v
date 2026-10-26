module uart_tx #(
    parameter integer CLK_HZ = 50000000,
    parameter integer BAUD   = 115200
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    input  wire       parity_en,
    output reg        tx,
    output wire       tx_busy
);

    localparam integer CLKS_PER_BIT =
        (CLK_HZ + BAUD / 2) / BAUD;
    localparam integer COUNT_W =
        (CLKS_PER_BIT < 2) ? 1 : $clog2(CLKS_PER_BIT);

    localparam [2:0] TX_IDLE   = 3'd0,
                     TX_START  = 3'd1,
                     TX_DATA   = 3'd2,
                     TX_PARITY = 3'd3,
                     TX_STOP   = 3'd4;

    reg [2:0] state;
    reg [COUNT_W-1:0] clk_count;
    reg [2:0] bit_index;
    reg [7:0] data_reg;
    reg parity_reg;
    reg parity_en_reg;

    assign tx_busy = (state != TX_IDLE);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state         <= TX_IDLE;
            clk_count     <= 0;
            bit_index     <= 0;
            data_reg      <= 0;
            parity_reg    <= 0;
            parity_en_reg <= 0;
            tx            <= 1'b1;
        end else begin
            case (state)
                TX_IDLE: begin
                    tx        <= 1'b1;
                    clk_count <= 0;
                    bit_index <= 0;

                    if (tx_start) begin
                        data_reg      <= tx_data;
                        parity_en_reg <= parity_en;
                        parity_reg    <= ^tx_data;
                        tx            <= 1'b0;
                        state         <= TX_START;
                    end
                end

                TX_START: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        tx        <= data_reg[0];
                        state     <= TX_DATA;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                TX_DATA: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;

                        if (bit_index == 3'd7) begin
                            if (parity_en_reg) begin
                                tx    <= parity_reg;
                                state <= TX_PARITY;
                            end else begin
                                tx    <= 1'b1;
                                state <= TX_STOP;
                            end
                        end else begin
                            bit_index <= bit_index + 1'b1;
                            data_reg  <= {1'b0, data_reg[7:1]};
                            tx        <= data_reg[1];
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                TX_PARITY: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        tx        <= 1'b1;
                        state     <= TX_STOP;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                TX_STOP: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        tx        <= 1'b1;
                        state     <= TX_IDLE;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                default: begin
                    state     <= TX_IDLE;
                    clk_count <= 0;
                    tx        <= 1'b1;
                end
            endcase
        end
    end

endmodule
