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
                     input signed [15:0] leftBorder,
                     input signed [15:0] rightBorder,
                     input signed [6:0] coeffs [0:5],
                     output reg status,
                     output reg signed [15:0] minimum,
                     output reg signed [15:0] maximum);

    /* Fixed point (16|10) related variables */
    parameter FXP_MUL = 1024;
    parameter FXP_SHIFT = 10;

    /* Derivative calculation variables */
    reg signed [6:0] deriv_coeffs [0:5] = {0, 1, 2, 3, 4, 5};
    reg signed [6:0] deriv [0:5] = {0, 0, 0, 0, 0, 0};

    /* Zero cross regions borders */
    parameter N_STEP = 3;
    reg [15:0] step_delta = 0;
    reg signed [15:0] anchor_point = 0;
    reg signed [3:0] current_border_number = 0;
    reg signed [15:0] first_zero_cross_borders [0:3] = {0, 0, 0, 0};
    reg signed [15:0] second_zero_cross_borders [0:3] = {0, 0, 0, 0};

    /* Root calculation variables */
    parameter signed [15:0] EPSILON = 10;
    reg [3:0] number_of_roots = 0;
    reg signed [15:0] root_x_values [0:3];

    /* Temp variables */
    reg signed [15:0] temp_min = 0;
    reg signed [15:0] temp_max = 0;

    reg signed [15:0] temp_y1 = 0;
    reg signed [15:0] temp_y2 = 0;

    reg signed [15:0] temp_root_y = 0;

    /* FSM variables */
    typedef enum {  START_CLEANUP,
                    BORDER_CALC,
                    DERIV_CALC,
                    ZERO_CROSS_FIND,
                    BISECTION,
                    CMP_WITH_BORDERS,
                    END_CLEANUP } state_T;
	state_T state;
    always @(posedge clk) 
    begin
        if(reset == 1'b1)
        begin
            status <= 0;
            state <= START_CLEANUP;
        end
        else 
        begin
            case (state)
                START_CLEANUP: begin
                    status <= 0;
                    anchor_point = leftBorder;
                    current_border_number = 0;
                    number_of_roots = 0;
                    step_delta = 1; // (abs(leftBorder) + abs(rightBorder)) / N_STEP; - for later use
                    state <= (request == 1) ? BORDER_CALC : START_CLEANUP;
                end
                BORDER_CALC: begin
                    /* Assume that left boarder in min and right boarder is max */
                    temp_min = funcVal(coeffs, leftBorder, 6);
                    temp_max = funcVal(coeffs, rightBorder, 6);
                    if (temp_max < temp_min)
                    begin
                        /* Wrong assumption flip the values */
                        temp_min = temp_max ^ temp_min;
                        temp_max = temp_min ^ temp_max;
                        temp_min = temp_max ^ temp_min;

                    end
                        state <= DERIV_CALC;
                end
                DERIV_CALC: begin
                    integer i;
                    for (i = 0; i < 5; i++) begin
                        deriv[i] = deriv_coeffs[i+1] * coeffs[i+1];
                    end
                    state <= ZERO_CROSS_FIND;
                end
                ZERO_CROSS_FIND: begin
                    first_zero_cross_borders[current_border_number] = anchor_point;
                    second_zero_cross_borders[current_border_number] = anchor_point + step_delta;

                    temp_y1 = funcVal(deriv, first_zero_cross_borders[current_border_number], 5);
                    temp_y2 = funcVal(deriv, second_zero_cross_borders[current_border_number], 5);

                    if ((temp_y1 * temp_y2) <= 0) 
                    begin
                        /* Potential root of a function found - latch values of anchors */
                        current_border_number++;
                    end
                    anchor_point += step_delta;

                    if ((anchor_point >= rightBorder) || (current_border_number > 4)) 
                    begin
                        
                        current_border_number--;
                 
                        number_of_roots <= current_border_number;
                        state <= BISECTION;
                    end
                end
                BISECTION: begin
                    do begin
                        root_x_values[current_border_number] = (first_zero_cross_borders[current_border_number] +  
                                                                second_zero_cross_borders[current_border_number]) / 2;
                        temp_root_y = funcVal(deriv, root_x_values[current_border_number], 5);

                        if(root_x_values[current_border_number] * first_zero_cross_borders[current_border_number] < 0)
                        begin
                            second_zero_cross_borders[current_border_number] = root_x_values[current_border_number];
                        end
                        else
                        begin
                            first_zero_cross_borders[current_border_number] = root_x_values[current_border_number];
                        end
                    end while (temp_root_y > EPSILON || temp_root_y < -EPSILON);
                    current_border_number--;
                    if(current_border_number < 0)
                    begin
                        state <= CMP_WITH_BORDERS;
                    end 
                end
                CMP_WITH_BORDERS: begin
                    integer i;
                    for (i = number_of_roots; i >= 0; i--) 
                    begin
                        if(funcVal(coeffs, root_x_values[i], 6) > temp_max)
                        begin
                            temp_max = funcVal(coeffs, root_x_values[i], 6);
                        end
                        if(funcVal(coeffs, root_x_values[i], 6) < temp_min)
                        begin
                            temp_min = funcVal(coeffs, root_x_values[i], 6);
                        end
                    end
                    state <= END_CLEANUP;
                end
                END_CLEANUP: begin
                    minimum = temp_min;
                    maximum = temp_max;
                    status <= 1;
                    state <= (request == 0) ? START_CLEANUP : END_CLEANUP;
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
    function signed [15:0] funcVal (input signed [6:0] coeffs [0:5],
                            input signed [15:0] x, 
                            input [3:0] size);
        begin
            //static reg power = size;
            funcVal = 0;
            while (size != 0) 
            begin
                size--;
                funcVal += (coeffs[size] * (x ** size));
            end
        end
    endfunction
    
    function [15:0] abs (input signed [15:0] a);           
        begin
        if(a<0)
           abs=-a;
        else 
           abs=a;
        end
    endfunction
endmodule

