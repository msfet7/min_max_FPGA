module uart_rx_sniffer #
(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD     = 115200
)
(
    input  wire clk,
    input  wire rst,
    input  wire rx,

    output reg [7:0] rx_byte,
    output reg       rx_valid
);

    localparam integer BAUD_DIV = CLK_FREQ / BAUD;
    localparam integer HALF_BAUD = BAUD_DIV / 2;

    reg [15:0] clk_cnt = 0;
    reg [3:0]  bit_idx = 0;
    reg [7:0]  shift   = 0;

    typedef enum reg [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t state = IDLE;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            clk_cnt <= 0;
            bit_idx <= 0;
            rx_valid <= 0;
        end else begin
            rx_valid <= 0;

            case (state)

                // -------------------------
                // Wait for start bit
                // -------------------------
                IDLE: begin
                    clk_cnt <= 0;
                    bit_idx <= 0;

                    if (rx == 0) begin
                        state <= START;
                        clk_cnt <= HALF_BAUD;
                    end
                end

                // -------------------------
                // Confirm start bit center
                // -------------------------
                START: begin
                    if (clk_cnt == 0) begin
                        if (rx == 0) begin
                            state <= DATA;
                            clk_cnt <= BAUD_DIV;
                            bit_idx <= 0;
                        end else begin
                            state <= IDLE;
                        end
                    end else begin
                        clk_cnt <= clk_cnt - 1;
                    end
                end

                // -------------------------
                // Sample 8 data bits
                // -------------------------
                DATA: begin
                    if (clk_cnt == 0) begin
                        clk_cnt <= BAUD_DIV;
                        shift[bit_idx] <= rx;

                        if (bit_idx == 7)
                            state <= STOP;
                        else
                            bit_idx <= bit_idx + 1;
                    end else begin
                        clk_cnt <= clk_cnt - 1;
                    end
                end

                // -------------------------
                // Stop bit + output byte
                // -------------------------
                STOP: begin
                    if (clk_cnt == 0) begin
                        rx_byte  <= shift;
                        rx_valid <= 1;
                        state <= IDLE;
                    end else begin
                        clk_cnt <= clk_cnt - 1;
                    end
                end

            endcase
        end
    end

endmodule