
`timescale 1ns/1ps

module main_tb;

    reg clk;
    reg reset;
    reg request;

    reg [31:0] leftBorder;
    reg [31:0] rightBorder;

    reg signed [31:0] coeffs [0:5];

    wire status;
    wire signed [31:0] minimum;
    wire signed [31:0] maximum;

    parameter FF_MUL = 65536;
    minMaxModule dut (
        .clk(clk),
        .reset(reset),
        .request(request),
        .leftBorder(leftBorder),
        .rightBorder(rightBorder),
        .coeffs(coeffs),
        .status(status),
        .minimum(minimum),
        .maximum(maximum)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        /* Test#1 */
        reset       = 1;
        request     = 0;
        leftBorder  = 0;
        rightBorder = 0;
        coeffs = {0, 0, 0, 0, 0, 0};

        // Reset modułu
        #20;
        reset = 0;
        coeffs = {1, -10, -2, 0, 0, 0};
        leftBorder  = -6 * FF_MUL;
        rightBorder =  1.2 * FF_MUL;

        @(posedge clk);
        request = 1;

        @(posedge clk);
        request = 0;

        wait(status == 1);
        #20
        
        /* Test#2 */
        reset       = 1;
        request     = 0;
        leftBorder  = 0;
        rightBorder = 0;
        coeffs = {0, 0, 0, 0, 0, 0};

        // Reset modułu
        #20;
        reset = 0;
        coeffs = {-1, 4, -2, 0, 6, 0};
        leftBorder  = -1.1 * FF_MUL;
        rightBorder =  -0.2 * FF_MUL;

        @(posedge clk);
        request = 1;

        @(posedge clk);
        request = 0;

        wait(status == 1);
        #20;
        
        /* Test#3 */
        reset       = 1;
        request     = 0;
        leftBorder  = 0;
        rightBorder = 0;
        coeffs = {0, 0, 0, 0, 0, 0};

        // Reset modułu
        #20;
        reset = 0;
        coeffs = {1, 0, -2, -10, 9, 0};
        leftBorder  = -0.6 * FF_MUL;
        rightBorder =  1.2 * FF_MUL;

        @(posedge clk);
        request = 1;

        @(posedge clk);
        request = 0;

        wait(status == 1);
        #20;
        
        /* Test#4 */
        reset       = 1;
        request     = 0;
        leftBorder  = 0;
        rightBorder = 0;
        coeffs = {0, 0, 0, 0, 0, 0};

        // Reset modułu
        #20;
        reset = 0;
        coeffs = {0, -7, 7, 1, -3, 0};
        leftBorder  = -2 * FF_MUL;
        rightBorder =  2 * FF_MUL;

        @(posedge clk);
        request = 1;

        @(posedge clk);
        request = 0;

        wait(status == 1);
        #20;
        
        /* Test#5 */
        reset       = 1;
        request     = 0;
        leftBorder  = 0;
        rightBorder = 0;
        coeffs = {0, 0, 0, 0, 0, 0};

        // Reset modułu
        #20;
        reset = 0;
        coeffs = {0, -2, 1, 0, 5, -8};
        leftBorder  = -2 * FF_MUL;
        rightBorder =  1 * FF_MUL;

        @(posedge clk);
        request = 1;

        @(posedge clk);
        request = 0;

        wait(status == 1);
        #20;
        
        
        $finish;
    end

endmodule
