//Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2018.3 (lin64) Build 2405991 Thu Dec  6 23:36:41 MST 2018
//Date        : Wed Jun 17 18:43:23 2026
//Host        : archlinux running 64-bit Arch Linux
//Command     : generate_target mb_design_wrapper.bd
//Design      : mb_design_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module mb_design_wrapper
   (diff_clock_rtl_clk_n,
    diff_clock_rtl_clk_p,
    reset_rtl,
    uart_rtl_rxd,
    uart_rtl_txd);
  input diff_clock_rtl_clk_n;
  input diff_clock_rtl_clk_p;
  input reset_rtl;
  input uart_rtl_rxd;
  output uart_rtl_txd;

  wire diff_clock_rtl_clk_n;
  wire diff_clock_rtl_clk_p;
  wire reset_rtl;
  wire uart_rtl_rxd;
  wire uart_rtl_txd;

  mb_design mb_design_i
       (.diff_clock_rtl_clk_n(diff_clock_rtl_clk_n),
        .diff_clock_rtl_clk_p(diff_clock_rtl_clk_p),
        .reset_rtl(reset_rtl),
        .uart_rtl_rxd(uart_rtl_rxd),
        .uart_rtl_txd(uart_rtl_txd));
endmodule
