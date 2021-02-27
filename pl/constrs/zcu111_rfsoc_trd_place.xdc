
# GPIO LEDs
#set_property PACKAGE_PIN AR13 [get_ports {led_0}]
#set_property IOSTANDARD LVCMOS18 [get_ports {led_0}]
#set_property PACKAGE_PIN AP13 [get_ports {led_1}]
#set_property IOSTANDARD LVCMOS18 [get_ports {led_1}]
#set_property PACKAGE_PIN AR16 [get_ports "led_2"] ;
#set_property IOSTANDARD LVCMOS18 [get_ports "led_2"] ;
#set_property PACKAGE_PIN AP16 [get_ports {led_3[0]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {led_3[0]}]
#set_property PACKAGE_PIN AP15 [get_ports {led_4}]
#set_property IOSTANDARD LVCMOS18 [get_ports {led_4}]
#set_property PACKAGE_PIN AN16 [get_ports "led_5"] ;

#set_property PACKAGE_PIN AN16 [get_ports {led_5}]
#set_property IOSTANDARD LVCMOS18 [get_ports {led_5}]

#set_property PACKAGE_PIN AN17 [get_ports {led_6}]
#set_property IOSTANDARD LVCMOS18 [get_ports {led_6}]

#set_property PACKAGE_PIN AV15 [get_ports {led_7}]
#set_property IOSTANDARD LVCMOS18 [get_ports {led_7}]

#set_property PACKAGE_PIN AF16 [get_ports start_bw_monitor_0]
#set_property IOSTANDARD LVCMOS18 [get_ports start_bw_monitor_0]


set_property PACKAGE_PIN AL16 [get_ports {CLK_DIFF_1_PL_CLK_clk_p[0]}]
set_property PACKAGE_PIN AL15 [get_ports {CLK_DIFF_1_PL_CLK_clk_n[0]}]
set_property PACKAGE_PIN AK17 [get_ports {CLK_DIFF_2_SYSREF_clk_p[0]}]
set_property PACKAGE_PIN AK16 [get_ports {CLK_DIFF_2_SYSREF_clk_n[0]}]

set_property IOSTANDARD LVDS [get_ports {CLK_DIFF_1_PL_CLK_clk_p[0]}]
set_property IOSTANDARD LVDS [get_ports {CLK_DIFF_1_PL_CLK_clk_n[0]}]
set_property IOSTANDARD LVDS [get_ports {CLK_DIFF_2_SYSREF_clk_p[0]}]
set_property IOSTANDARD LVDS [get_ports {CLK_DIFF_2_SYSREF_clk_n[0]}]

set_property DIFF_TERM_ADV TERM_100 [get_ports {CLK_DIFF_1_PL_CLK_clk_p[0]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {CLK_DIFF_2_SYSREF_clk_p[0]}]

