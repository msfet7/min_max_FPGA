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
           [in]  coeffs - coefficients of a function (max 5)
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
                     input [3:0] coeffs [0:4],
                     output reg status,
                     output reg [15:0] minimum [0:1],
                     output reg [15:0] maximum [0:1]);

    typedef enum {  START_CLEANUP,
                    BORDER_CALC,
                    DERIV_CALC,
                    ZERO_CROSS_FIND,
                    BISECTION,
                    CMP_WITH_BORDERS } state_T;
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
            if(request == 1)
            begin
                case (state)
                    START_CLEANUP: begin
                        /* START_CLEANUP code */
                    end
                    BORDER_CALC: begin
                        /* BORDER_CALC code */
                    end
                    DERIV_CALC: begin
                        /* DERIV_CALC code */
                    end
                    ZERO_CROSS_FIND: begin
                        /* ZERO_CROSS_FIND code */
                    end
                    BISECTION: begin
                        /* BISECTION code */
                    end
                    CMP_WITH_BORDERS: begin
                        /* CMP_WITH_BORDERS code */
                    end 
                    default: begin
                        /* Unreachable in theory */
                    end
                endcase
            end
        end
    end
    
endmodule
