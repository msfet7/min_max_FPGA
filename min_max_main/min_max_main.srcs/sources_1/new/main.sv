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
    reg [31:0] step = 0.1 * FXP_MUL;
    reg signed [31:0] current_x = 0;
    reg signed [31:0] current_y = 0;
    reg signed [31:0] current_min = 'hFFFFFFFF;
    reg signed [31:0] current_max = 0;
    
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
                    /* Assume that left boarder in min and right boarder is max */
                    current_min = funcVal(coeffs, leftBorder , 6);
                    current_max = funcVal(coeffs, rightBorder , 6);
                    if (current_max < current_min)
                    begin
                        /* Wrong assumption flip the values */
                        current_min = current_max ^ current_min;
                        current_max = current_min ^ current_max;
                        current_min = current_max ^ current_min;

                    end
                        state <= SCAN;
                end
                SCAN: begin
                    current_y = funcVal(coeffs, current_x, 6);

                    if(current_y > current_max)
                    begin
                        current_max = current_y;
                    end
                    if(current_y < current_min)
                    begin
                        current_min = current_y;
                    end
                    current_x += step;

                    if(current_x > rightBorder)
                    begin
                        maximum <= current_max;
                        minimum <= current_min;
                        state = FINISH;
                    end
                end 
                FINISH: begin
                    /* Cleanup after SCAN */
                    current_max = 0;
                    current_min = 'hFFFFFFFF;
                    current_x = leftBorder;

                    /* Set status and go to IDLE if no request*/
                    status <= 1;
                    state <= (request == 0) ? IDLE : FINISH;
                end 
                default: begin
                    /* Unreachable in theory */
                end
            endcase
        end
    end
    
    /**
        Brief: Function for calculating f(x), where f has given coefficients and size 
        Params: [in]  coeffs - function coefficients 
                [in]  x - the value for which the equation is calculated
                [in]  size - number of maximum possible elements in function
        Returns: f(x) value
    */
    function signed [31:0] funcVal (input signed [31:0] coeffs [0:5],
                            input signed [31:0] x, 
                            input [3:0] size);
        begin
            static reg signed [63:0] temp64 = 0;
            static reg signed [31:0] temp32 = coeffs[size-1] * FXP_MUL;
            funcVal = 0;
            size--;
            while (size != 0) 
            begin             
                temp64 = temp32 * x;
                temp32 = (temp64 >>> FXP_SHIFT)  + coeffs[size-1] * FXP_MUL;
                size--;  
            end
            funcVal = temp32;
        end
    endfunction

endmodule

