# Clock
set_property PACKAGE_PIN Y9  [get_ports diff_clock_rtl_clk_p]
set_property PACKAGE_PIN Y8  [get_ports diff_clock_rtl_clk_n]
set_property IOSTANDARD DIFF_SSTL15 [get_ports diff_clock_rtl_clk_p]
set_property IOSTANDARD DIFF_SSTL15 [get_ports diff_clock_rtl_clk_n]

# Reset
set_property PACKAGE_PIN P16 [get_ports reset_rtl]
set_property IOSTANDARD LVCMOS18 [get_ports reset_rtl]


# UART
set_property PACKAGE_PIN Y11  [get_ports uart_rtl_rxd]
set_property PACKAGE_PIN AA11 [get_ports uart_rtl_txd]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rtl_rxd]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rtl_txd]