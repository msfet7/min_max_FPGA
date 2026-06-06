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
                     input [15:0] leftBorder,
                     input [15:0] rightBorder,
                     input signed [3:0] coeffs [0:5],
                     output reg status,
                     output reg signed [15:0] minimum [0:1],
                     output reg signed [15:0] maximum [0:1]);

    /* Fixed point (16|10) related variables */
    parameter FXP_MUL = 1024;
    parameter FXP_SHIFT = 10;

    /* Derivative calculation variables */
    reg signed [3:0] deriv_coeffs [0:4] = {5, 4, 3, 2, 1};

    /* Zero cross regions borders */
    parameter N_STEP = 100;
    reg [15:0] step_delta = (leftBorder + rightBorder) / N_STEP;
    reg [15:0] anchor_point;
    reg current_border_number = 0;
    reg signed [15:0] first_zero_cross_borders [0:3];
    reg signed [15:0] second_zero_cross_borders [0:3];

    /* Root calculation variables */
    parameter EPSILON = 0.01 * FXP_MUL;
    reg number_of_roots = 0;
    reg signed [15:0] root_x_values [0:3];

    /* Temp variables */
    reg signed [15:0] temp_min [0:1];
    reg signed [15:0] temp_max [0:1];

    reg signed [15:0] temp_y1;
    reg signed [15:0] temp_y2;

    reg signed [15:0] temp_root_y;

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
                    state <= (request == 1) ? BORDER_CALC : START_CLEANUP;
                end
                BORDER_CALC: begin
                    /* Assume that left boarder in min and right boarder is max */
                    temp_min[1] = funcVal(coeffs, leftBorder, 6);
                    temp_max[1] = funcVal(coeffs, rightBorder, 6);
                    if (temp_max[1] < temp_min[1])
                    begin
                        /* Wrong assumption flip the values */
                        temp_min[1] = temp_max[1] ^ temp_min[1];
                        temp_max[1] = temp_min[1] ^ temp_max[1];
                        temp_min[1] = temp_max[1] ^ temp_min[1];

                        temp_max[0] = leftBorder;
                        temp_min[0] = rightBorder;
                    end
                    else
                    begin
                        temp_max[0] = rightBorder;
                        temp_min[0] = leftBorder;
                    end
                    state = DERIV_CALC;
                end
                DERIV_CALC: begin
                    for (intager i = 0; i < 5; i++) begin
                        deriv_coeffs[i] *= coeffs[i];
                    end
                end
                ZERO_CROSS_FIND: begin
                    first_zero_cross_borders[current_border_number] = anchor_point;
                    second_zero_cross_borders[current_border_number] = anchor_point + step_delta;

                    temp_y1 = funcVal(deriv_coeffs, first_zero_cross_borders[current_border_number], 5);
                    temp_y2 = funcVal(deriv_coeffs, second_zero_cross_borders[current_border_number], 5);

                    if ((temp_y1 * temp_y2) < 0) 
                    begin
                        /* Potential root of a function found - latch values of anchors */
                        current_border_number++;
                    end
                    anchor_point += step_delta;

                    if ((anchor_point >= rightBorder) || (current_border_number > 4)) 
                    begin
                        if(current_border_number > 4)
                        begin
                            current_border_number--;
                        end
                        number_of_roots <= current_border_number;
                        state <= BISECTION;
                    end
                end
                BISECTION: begin
                    do begin
                        root_x_values[current_border_number] = (first_zero_cross_borders[current_border_number] +  
                                                                second_zero_cross_borders[current_border_number]) / 2;
                        temp_root_y = funcVal(deriv_coeffs, root_x_values[current_border_number], 5);

                        if(root_x_values[current_border_number] * first_zero_cross_borders[current_border_number] < 0)
                        begin
                            second_zero_cross_borders[current_border_number] = root_x_values[current_border_number];
                        end
                        else
                        begin
                            first_zero_cross_borders[current_border_number] = root_x_values[current_border_number];
                        end

                    end while (temp_root_y < EPSILON && temp_root_y > -EPSILON);
                    current_border_number--;
                end
                CMP_WITH_BORDERS: begin
                    for (integer i = number_of_roots; i >= 0; i--) 
                    begin
                        if(funcVal(coeffs, root_x_values[i], 6) > temp_max[1])
                        begin
                            temp_max[1] = funcVal(coeffs, root_x_values[i], 6);
                            temp_max[0] = root_x_values[i];
                        end
                        if(funcVal(coeffs, root_x_values[i], 6) < temp_min[1])
                        begin
                            temp_min[1] = funcVal(coeffs, root_x_values[i], 6);
                            temp_min[0] = root_x_values[i];
                        end
                    end
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
    
endmodule

/**
    Brief: Function for calculating f(x), where f has given coefficients and size 
    Params: [in]  coeffs - function coefficients 
            [in]  x - the value for which the equation is calculated
            [in]  size - number of maximum possible elements in function
    Returns: f(x) value
*/
function signed [15:0] funcVal (input signed [3:0] coeffs [0:5],
                        input [15:0] x, 
                        input size);
	begin
        static reg power = size;
		while (power != 0) 
        begin
            power--;
            funcVal += coeffs[power] * (x ** power);
        end
	end
endfunction