/** 
*   Main file of a project Min/Max Finder
*   Authors: Mateusz Szpot <matszpo@student.agh.edu.pl>
*            Krzysztof Paryż <paryzk@student.agh.edu.pl>
*/

module minMaxModule (input clk,
                     input reset,
                     input request,
                     input signed [31:0] leftBorder,
                     input signed [31:0] rightBorder,
                    input signed [31:0] coeff0,
                    input signed [31:0] coeff1,
                    input signed [31:0] coeff2,
                    input signed [31:0] coeff3,
                    input signed [31:0] coeff4,
                    input signed [31:0] coeff5,
                     output reg status,
                     output reg signed [31:0] minimum,
                     output reg signed [31:0] maximum);

 
    /* Fixed-point Q16.16 */
    localparam int FXP_SHIFT = 16;
    localparam int FXP_MUL   = 1 << FXP_SHIFT;      // 65536
// STEP = floor(0.1 × 2^16) = floor(6553.6) = 6553
localparam logic signed [31:0] STEP = 32'sd6553;
    /* Largest positive signed 32-bit value (used as initial minimum sentinel) */
    localparam logic signed [31:0] MAX_POS = 32'h7FFF_FFFF;

wire signed [31:0] coeffs [0:5];
assign coeffs[0] = coeff0;
assign coeffs[1] = coeff1;
assign coeffs[2] = coeff2;
assign coeffs[3] = coeff3;
assign coeffs[4] = coeff4;
assign coeffs[5] = coeff5;


    /* ------------------------------------------------------------------ */
    /*  State machine                                                       */
    /* ------------------------------------------------------------------ */
    typedef enum logic [2:0] {
        IDLE,
        CALC_INIT,   // load coeffs[size-1] into accumulator
        CALC_STEP,   // one Horner iteration per cycle
        COMPARE,     // update min/max, advance x
        FINISH
    } state_t;

    state_t state;

    /* Scanning registers */
    logic signed [31:0] current_x;
    logic signed [31:0] current_min;
    logic signed [31:0] current_max;

    /* Horner accumulator - 64-bit to avoid overflow during multiply */
    logic signed [63:0] acc64;
    logic signed [31:0] acc32;          // acc64 right-shifted after each MAC
    logic        [ 2:0] coeff_idx;      // counts from (size-1) down to 0
    logic               calc_for_left;  // 1 = evaluating leftBorder, 0 = current_x

    /* The x value currently being evaluated */
    logic signed [31:0] eval_x;

    /* Replicate coefficient registers to reduce fanout */
    (* max_fanout = 4 *) logic signed [31:0] coeffs_r [0:5];

    always_ff @(posedge clk) begin : REG_COEFFS
        for (int i = 0; i < 6; i++)
            coeffs_r[i] <= coeffs[i];
    end

    /* ------------------------------------------------------------------ */
    /*  Main FSM                                                            */
    /* ------------------------------------------------------------------ */
    always_ff @(posedge clk) begin
        if (reset) begin
            status      <= 1'b0;
            state       <= IDLE;
            current_x   <= '0;
            current_min <= MAX_POS;
            current_max <= ~MAX_POS;    // most-negative signed value
            minimum     <= '0;
            maximum     <= '0;
        end
        else begin
            case (state)

                /* -------------------------------------------------------- */
                IDLE: begin
                    status    <= 1'b0;
                    current_x <= leftBorder;
                    if (request) begin
                        /* First: evaluate f(leftBorder) */
                        current_min   <= MAX_POS;
                        current_max   <= ~MAX_POS;
                        calc_for_left <= 1'b1;
                        eval_x        <= leftBorder;
                        acc32         <= coeffs_r[5]; // seed Horner with highest coeff
                        coeff_idx     <= 3'd4;        // next coeff to fold in
                        state         <= CALC_INIT;
                    end
                end

                /* -------------------------------------------------------- */
                /*  CALC_INIT: register the first Horner seed (one cycle)   */
                /* -------------------------------------------------------- */
                CALC_INIT: begin
                    // acc32 already latched in IDLE/COMPARE; just move to step loop
                    state <= CALC_STEP;
                end

                /* -------------------------------------------------------- */
                /*  CALC_STEP: acc32 = acc32 * x + coeffs[coeff_idx]        */
                /*  ONE iteration per clock → ~6-8 ns per cycle             */
                /* -------------------------------------------------------- */
                CALC_STEP: begin
                    acc64 <= acc32 * eval_x;           // 32×32 → 64
                    // Shift result back to Q16.16 and add next coeff
                    acc32 <= (acc64 >>> FXP_SHIFT) + coeffs_r[coeff_idx];

                    if (coeff_idx == 3'd0) begin
                        // Polynomial fully evaluated → go compare
                        state <= COMPARE;
                    end
                    else begin
                        coeff_idx <= coeff_idx - 3'd1;
                    end
                end

                /* -------------------------------------------------------- */
                /*  COMPARE: use acc32 as f(eval_x)                         */
                /* -------------------------------------------------------- */
                COMPARE: begin
                    /* Update min/max with the just-computed value */
                    if (acc32 < current_min) current_min <= acc32;
                    if (acc32 > current_max) current_max <= acc32;

                    if (calc_for_left) begin
                        /* Done with leftBorder; now evaluate rightBorder */
                        calc_for_left <= 1'b0;
                        eval_x        <= rightBorder;
                        acc32         <= coeffs_r[5];
                        coeff_idx     <= 3'd4;
                        state         <= CALC_INIT;
                    end
                    else begin
                        /* Done with current_x; advance */
                        current_x <= current_x + STEP;

                        if (current_x >= rightBorder) begin
                            /* Scan complete */
                            minimum <= current_min;
                            maximum <= current_max;
                            state   <= FINISH;
                        end
                        else begin
                            /* Evaluate next x */
                            eval_x    <= current_x + STEP;
                            acc32     <= coeffs_r[5];
                            coeff_idx <= 3'd4;
                            state     <= CALC_INIT;
                        end
                    end
                end

                /* -------------------------------------------------------- */
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