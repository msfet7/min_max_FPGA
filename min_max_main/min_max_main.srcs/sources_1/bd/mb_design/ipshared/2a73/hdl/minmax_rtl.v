/** 
*   Main file of a project Min/Max Finder
*   Authors: Mateusz Szpot <matszpo@student.agh.edu.pl>
*            Krzysztof Paryż <paryzk@student.agh.edu.pl>
*/

module minMaxModule (
    input  logic        clk,
    input  logic        reset,
    input  logic        request,
    input  logic signed [31:0] leftBorder,
    input  logic signed [31:0] rightBorder,
    input  logic signed [31:0] coeff0,
    input  logic signed [31:0] coeff1,
    input  logic signed [31:0] coeff2,
    input  logic signed [31:0] coeff3,
    input  logic signed [31:0] coeff4,
    input  logic signed [31:0] coeff5,
    output logic        status,
    output logic signed [31:0] minimum,
    output logic signed [31:0] maximum
);

    localparam int            FXP_SHIFT = 16;
    localparam logic signed [31:0] STEP    = 32'sd6553;
    localparam logic signed [31:0] MAX_POS = 32'h7FFF_FFFF;
    localparam logic signed [31:0] MIN_NEG = 32'h8000_0000;

    wire signed [31:0] coeffs [0:5];
    assign coeffs[0] = coeff0;
    assign coeffs[1] = coeff1;
    assign coeffs[2] = coeff2;
    assign coeffs[3] = coeff3;
    assign coeffs[4] = coeff4;
    assign coeffs[5] = coeff5;

    (* max_fanout = 4 *) logic signed [31:0] coeffs_r [0:5];
    always_ff @(posedge clk) begin : REG_COEFFS
        for (int i = 0; i < 6; i++)
            coeffs_r[i] <= coeffs[i];
    end

    typedef enum logic [1:0] {
        IDLE,
        CALC_STEP,
        COMPARE,
        FINISH
    } state_t;

    state_t state;

    logic mul_phase;

    logic signed [31:0] current_x;
    logic signed [31:0] current_min;
    logic signed [31:0] current_max;

    logic signed [63:0] acc64;
    logic signed [31:0] acc32;

    logic [2:0] coeff_idx;

    logic [1:0] eval_mode;
    localparam logic [1:0] MODE_LEFT  = 2'b00;
    localparam logic [1:0] MODE_RIGHT = 2'b01;
    localparam logic [1:0] MODE_GRID  = 2'b10;

    logic signed [31:0] eval_x;

    task automatic start_eval(input logic signed [31:0] x);
        eval_x    <= x;
        acc32     <= coeffs_r[5];
        coeff_idx <= 3'd4;
        mul_phase <= 1'b0;
        state     <= CALC_STEP;
    endtask

    always_ff @(posedge clk) begin
        if (reset) begin
            status      <= 1'b0;
            state       <= IDLE;
            current_x   <= '0;
            current_min <= MAX_POS;
            current_max <= MIN_NEG;
            minimum     <= '0;
            maximum     <= '0;
            mul_phase   <= 1'b0;
            eval_mode   <= MODE_LEFT;
        end
        else begin
            case (state)

                IDLE: begin
                    status <= 1'b1;
                    if (request) begin
                        status <= 1'b0;
                        current_min <= MAX_POS;
                        current_max <= MIN_NEG;
                        current_x   <= leftBorder;
                        eval_mode   <= MODE_LEFT;
                        start_eval(leftBorder);
                    end
                end

                CALC_STEP: begin
                    if (!mul_phase) begin
                        acc64     <= acc32 * eval_x;
                        mul_phase <= 1'b1;
                    end
                    else begin
                        acc32     <= (acc64 >>> FXP_SHIFT) + coeffs_r[coeff_idx];
                        mul_phase <= 1'b0;

                        if (coeff_idx == 3'd0)
                            state <= COMPARE;
                        else
                            coeff_idx <= coeff_idx - 3'd1;
                    end
                end

                COMPARE: begin
                    if (acc32 < current_min) current_min <= acc32;
                    if (acc32 > current_max) current_max <= acc32;

                    case (eval_mode)
                        MODE_LEFT: begin
                            eval_mode <= MODE_RIGHT;
                            start_eval(rightBorder);
                        end

                        MODE_RIGHT: begin
                            if (leftBorder + STEP < rightBorder) begin
                                current_x <= leftBorder + STEP;
                                eval_mode <= MODE_GRID;
                                start_eval(leftBorder + STEP);
                            end
                            else begin
                                minimum <= (acc32 < current_min) ? acc32 : current_min;
                                maximum <= (acc32 > current_max) ? acc32 : current_max;
                                state   <= FINISH;
                            end
                        end

                        MODE_GRID: begin
                            if (current_x + STEP < rightBorder) begin
                                current_x <= current_x + STEP;
                                start_eval(current_x + STEP);
                            end
                            else begin
                                minimum <= (acc32 < current_min) ? acc32 : current_min;
                                maximum <= (acc32 > current_max) ? acc32 : current_max;
                                state   <= FINISH;
                            end
                        end

                        default: state <= IDLE;
                    endcase
                end

                FINISH: begin
                    status <= 1'b1;
                    if (!request)
                        state <= IDLE;
                end

                default: state <= IDLE;

            endcase
        end
    end

endmodule