
`timescale 1ns/1ps

module main_tb;

    reg clk;
    reg reset;
    reg request;

    reg [15:0] leftBorder;
    reg [15:0] rightBorder;

    reg signed [6:0] coeffs [0:5];

    wire status;
    wire signed [15:0] minimum;
    wire signed [15:0] maximum;

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

        reset       = 1;
        request     = 0;
        leftBorder  = 0;
        rightBorder = 0;

        coeffs[0] = 0;
        coeffs[1] = 0;
        coeffs[2] = 0;
        coeffs[3] = 0;
        coeffs[4] = 0;
        coeffs[5] = 0;

        // Reset modułu
        #20;
        reset = 0;

        coeffs[0] =  -4; // C
        coeffs[1] =  0; // x
        coeffs[2] =  1; // x^2 
        coeffs[3] =  0; // x^3
        coeffs[4] =  0; // x^4z
        coeffs[5] =  0; // x^5

        leftBorder  = -5;
        rightBorder =  5;

        @(posedge clk);
        request = 1;

        @(posedge clk);
        request = 0;

        wait(status == 1);

        $display("--------------------------------");
        $display("Calculation finished");
        $display("Minimum = %d", minimum);
        $display("Maximum = %d", maximum);
        $display("--------------------------------");

        #20;
        $finish;
    end

endmodule
