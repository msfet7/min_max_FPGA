`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.06.2026 19:37:33
// Design Name: 
// Module Name: main_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns/1ps

module main_tb;

    reg clk;
    reg reset;
    reg request;

    reg [15:0] leftBorder;
    reg [15:0] rightBorder;

    reg signed [3:0] coeffs [0:5];

    wire status;
    wire signed [15:0] minimum;
    wire signed [15:0] maximum;

    // DUT
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

    // Clock 100 MHz
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin

        // Reset wartości wejściowych
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

        // f(x) = x² - 4
        coeffs[0] = -4;
        coeffs[1] =  0;
        coeffs[2] =  1;
        coeffs[3] =  0;
        coeffs[4] =  0;
        coeffs[5] =  0;

        // Przedział <-5,5>
        leftBorder  = -5;
        rightBorder =  5;

        // Zgłoszenie żądania
        @(posedge clk);
        request = 1;

        @(posedge clk);
        request = 0;

        // Czekaj aż moduł skończy
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
