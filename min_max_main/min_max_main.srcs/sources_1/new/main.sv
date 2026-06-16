/** 
*   Main file of a project Min/Max Finder
*   Authors: Mateusz Szpot <matszpo@student.agh.edu.pl>
*            Krzysztof Paryż <paryzk@student.agh.edu.pl>
*/

/**
    Brief: Module is implementing state machine, that will find minimum and maximum
            values of function with given 5 coefficients and borders. 
    Params: [in]  clk - clock 
            [in]  reset - reset signal, that clears status and resets state machine
            [in]  request - bit set by user if borders and coefficients are set
            [in]  leftBorder - left border of a function from which min/max values will be searched
            [in]  rightBorder - right border of a function yo which min/max values will be searched
            [in]  coeffs - coefficients of a function (max 6)
            [out] status - status of operation:
                        * 0 - output data not ready
                        * 1 - output data ready
            [out] minimum - found <x,y> coordinates of minimum
            [out] maximum - found <x,y> coordinates of maximum
*/



module minMaxModule (input clk,
                     input reset,
                     input request,
                     input signed [31:0] leftBorder,
                     input signed [31:0] rightBorder,
                     input signed [31:0] coeffs [0:5],
                     output reg status,
                     output reg signed [31:0] minimum,
                     output reg signed [31:0] maximum);
 
    /* Fixed point (32|16) related variables */
    parameter FXP_MUL = 2**16;
    parameter FXP_SHIFT = 16;
 
    /* min/max search variables */
    reg [31:0] step = 6554; // 0.1 * 2^16 = 6553.6 → 6554
 
    reg signed [31:0] current_x = 0;
    reg signed [31:0] current_y = 0;

    (* max_fanout = 4 *) reg signed [31:0] current_min = 32'h7FFFFFFF;
    (* max_fanout = 4 *) reg signed [31:0] current_max = 32'h80000000;
    
    /* FSM variables */
    typedef enum {  IDLE,
                    BORDER_CALC,
                    SCAN,
                    FINISH} state_T;
    state_T state;
 
    always @(posedge clk) 
    begin
        if(reset == 1'b1)
        begin
            status <= 0;
            state <= IDLE;
            current_x <= leftBorder;
            maximum  <= 0;
            minimum <= 0;
        end
        else 
        begin
            case (state)
                IDLE: begin
                    current_x <= leftBorder;
                    state = (request == 1'b1) ? BORDER_CALC : IDLE;
                end
                BORDER_CALC: begin
                    current_min <= 32'h7FFFFFFF;
                    current_max <= 32'h80000000;
                    state <= SCAN;
                end
                SCAN: begin

                    current_y = coeffs[5];
                    current_y = (current_y * current_x) >>> FXP_SHIFT + coeffs[4];
                    current_y = (current_y * current_x) >>> FXP_SHIFT + coeffs[3];
                    current_y = (current_y * current_x) >>> FXP_SHIFT + coeffs[2];
                    current_y = (current_y * current_x) >>> FXP_SHIFT + coeffs[1];
                    current_y = (current_y * current_x) >>> FXP_SHIFT + coeffs[0];
 
                    if(current_y > current_max)
                    begin
                        current_max <= current_y;
                    end
                    if(current_y < current_min)
                    begin
                        current_min <= current_y;
                    end
                    current_x <= current_x + step;
 
                    if(current_x + step > rightBorder)
                    begin
                        maximum <= current_max;
                        minimum <= current_min;
                        state <= FINISH;
                    end
                end 
                FINISH: begin
                    current_max <= 32'h80000000;
                    current_min <= 32'h7FFFFFFF;
                    current_x <= leftBorder;
 
                    status <= 1;
                    state <= (request == 0) ? IDLE : FINISH;
                end 
                default: begin
                end
            endcase
        end
    end
 
endmodule
 

