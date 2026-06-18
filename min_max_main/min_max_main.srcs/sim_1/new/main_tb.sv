`timescale 1ns/1ps

module main_tb;

    reg clk;
    reg reset;
    reg request;

    reg signed [31:0] leftBorder;
    reg signed [31:0] rightBorder;

    reg signed [31:0] coeff0;
    reg signed [31:0] coeff1;
    reg signed [31:0] coeff2;
    reg signed [31:0] coeff3;
    reg signed [31:0] coeff4;
    reg signed [31:0] coeff5;

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
        .coeff0(coeff0),
        .coeff1(coeff1),
        .coeff2(coeff2),
        .coeff3(coeff3),
        .coeff4(coeff4),
        .coeff5(coeff5),
        .status(status),
        .minimum(minimum),
        .maximum(maximum)
    );

    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end

    initial begin

        /* Test #1 */
        reset       = 1;
        request     = 0;
        leftBorder  = 0;
        rightBorder = 0;
        coeff0 = 0; coeff1 = 0; coeff2 = 0;
        coeff3 = 0; coeff4 = 0; coeff5 = 0;

        #20;
        reset = 0;

        coeff0 = 1 * FF_MUL;
        coeff1 = -10* FF_MUL;
        coeff2 = -2* FF_MUL;
        coeff3 = 0* FF_MUL;
        coeff4 = 0* FF_MUL;
        coeff5 = 0* FF_MUL;

        leftBorder  = -6 * FF_MUL;
        rightBorder = 12 * FF_MUL / 10;   // 1.2

        @(posedge clk);
        request = 1;

        @(posedge clk);
        request = 0;

        wait(status == 1);
        #20;

        /* Test #2 */
        reset       = 1;
        request     = 0;
        leftBorder  = 0;
        rightBorder = 0;
        coeff0 = 0; coeff1 = 0; coeff2 = 0;
        coeff3 = 0; coeff4 = 0; coeff5 = 0;

        #20;
        reset = 0;

        coeff0 = -1;
        coeff1 = 4;
        coeff2 = -2;
        coeff3 = 0;
        coeff4 = 6;
        coeff5 = 0;

        leftBorder  = -11 * FF_MUL / 10;  // -1.1
        rightBorder = -2 * FF_MUL / 10;   // -0.2

        @(posedge clk);
        request = 1;

        @(posedge clk);
        request = 0;

        wait(status == 1);
        #20;

        /* Test #3 */
        reset       = 1;
        request     = 0;
        leftBorder  = 0;
        rightBorder = 0;
        coeff0 = 0; coeff1 = 0; coeff2 = 0;
        coeff3 = 0; coeff4 = 0; coeff5 = 0;

        #20;
        reset = 0;

        coeff0 = 1;
        coeff1 = 0;
        coeff2 = -2;
        coeff3 = -10;
        coeff4 = 9;
        coeff5 = 0;

        leftBorder  = -6 * FF_MUL / 10;   // -0.6
        rightBorder = 12 * FF_MUL / 10;   // 1.2

        @(posedge clk);
        request = 1;

        @(posedge clk);
        request = 0;

        wait(status == 1);
        #20;

        /* Test #4 */
        reset       = 1;
        request     = 0;
        leftBorder  = 0;
        rightBorder = 0;
        coeff0 = 0; coeff1 = 0; coeff2 = 0;
        coeff3 = 0; coeff4 = 0; coeff5 = 0;

        #20;
        reset = 0;

        coeff0 = 0;
        coeff1 = -7;
        coeff2 = 7;
        coeff3 = 1;
        coeff4 = -3;
        coeff5 = 0;

        leftBorder  = -2 * FF_MUL;
        rightBorder =  2 * FF_MUL;

        @(posedge clk);
        request = 1;

        @(posedge clk);
        request = 0;

        wait(status == 1);
        #20;

        /* Test #5 */
        reset       = 1;
        request     = 0;
        leftBorder  = 0;
        rightBorder = 0;
        coeff0 = 0; coeff1 = 0; coeff2 = 0;
        coeff3 = 0; coeff4 = 0; coeff5 = 0;

        #20;
        reset = 0;

        coeff0 = 0;
        coeff1 = -2;
        coeff2 = 1;
        coeff3 = 0;
        coeff4 = 5;
        coeff5 = -8;

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