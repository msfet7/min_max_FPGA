`timescale 1 ps / 1 ps

module tb_top;

reg clk;
reg rst;
wire txd;

// -------------------------
// 100 MHz clock
// -------------------------
initial clk = 0;
always #5000 clk = ~clk;

// -------------------------
// RESET (clock aligned)
// -------------------------
initial begin
    rst = 1;
    repeat (50) @(posedge clk);
    rst = 0;
end

// -------------------------
// DUT
// -------------------------
mb_design_wrapper DUT (
    .diff_clock_rtl_clk_p(clk),
    .diff_clock_rtl_clk_n(~clk),
    .reset_rtl(rst),
    .uart_rtl_rxd(1'b1),
    .uart_rtl_txd(txd)
);

endmodule