`timescale 1ns / 1ps

module mb_design_tb();

    reg clk_n;
    reg clk_p;
    reg rst;
    reg rst_0;

    wire [1:0]  gpio_control;
    wire [31:0] gpio_maximum;
    wire [31:0] gpio_minimum;
    wire [0:0]  gpio_status;

    // Przejście na typ real do podglądu w symulatorze
    real r_minimum;
    real r_maximum;

    initial begin
        rst   = 1'b1;
        rst_0 = 1'b0;
        #40;
        rst   = 1'b0;
        rst_0 = 1'b1;
    end

    initial begin
        clk_n = 1'b0;
        clk_p = 1'b1;
    end

    always begin
        #5;
        clk_n = ~clk_n;
        clk_p = ~clk_p;
    end

    // Poprawna konwersja Fixed-Point Q16.16 do Real dla XSIM
    always @* begin
        r_minimum = $signed(gpio_minimum) / 65536.0;
        r_maximum = $signed(gpio_maximum) / 65536.0;
    end

    mb_design_wrapper mb_design_inst (
        .diff_clock_rtl_clk_n(clk_n),
        .diff_clock_rtl_clk_p(clk_p),
        .gpio_control_tri_io(gpio_control),
        .gpio_maximum_tri_io(gpio_maximum),
        .gpio_minimum_tri_io(gpio_minimum),
        .gpio_status_tri_io(gpio_status),
        .reset_rtl(rst),
        .reset_rtl_0(rst_0)
    );

endmodule