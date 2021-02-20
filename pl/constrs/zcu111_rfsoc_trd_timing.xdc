
create_clock -period 8.138 -name pl_clk [get_ports {CLK_DIFF_1_PL_CLK_clk_p[0]}]

create_generated_clock -name clk_out1_zcu111_rfsoc_trd_ADC_clk_wiz_0_0_5 [get_pins zcu111_rfsoc_trd_i/clk_block/ADC_clk_wiz_0/inst/plle4_adv_inst/CLKOUT0]
create_generated_clock -name clk_out1_zcu111_rfsoc_trd_ADC_clk_wiz_0_0_6 [get_pins zcu111_rfsoc_trd_i/clk_block/ADC_clk_wiz_1/inst/plle4_adv_inst/CLKOUT0]
create_generated_clock -name clk_out1_zcu111_rfsoc_trd_ADC_clk_wiz_0_0_7 [get_pins zcu111_rfsoc_trd_i/clk_block/ADC_clk_wiz_2/inst/plle4_adv_inst/CLKOUT0]
create_generated_clock -name clk_out1_zcu111_rfsoc_trd_ADC_clk_wiz_0_0_8 [get_pins zcu111_rfsoc_trd_i/clk_block/ADC_clk_wiz_3/inst/plle4_adv_inst/CLKOUT0]

create_generated_clock -name pl_clk_adc_1 [get_pins zcu111_rfsoc_trd_i/mts_clk/clk_wiz_0/inst/mmcme4_adv_inst/CLKOUT0]
create_generated_clock -name mts_clk_pl_clk_dac [get_pins zcu111_rfsoc_trd_i/mts_clk/clk_wiz_1/inst/mmcme4_adv_inst/CLKOUT0]

create_generated_clock -name mts_clk_pl_adc_clk_45 [get_pins zcu111_rfsoc_trd_i/mts_clk/clk_wiz_0/inst/mmcme4_adv_inst/CLKOUT1]
create_generated_clock -name mts_clk_pl_dac_clk_45 [get_pins zcu111_rfsoc_trd_i/mts_clk/clk_wiz_1/inst/mmcme4_adv_inst/CLKOUT1]
create_generated_clock -name clk_out3_zcu111_rfsoc_trd_clk_wiz_0_0 [get_pins zcu111_rfsoc_trd_i/mts_clk/clk_wiz_0/inst/mmcme4_adv_inst/CLKOUT2]
create_generated_clock -name clk_out3_zcu111_rfsoc_trd_clk_wiz_1_0 [get_pins zcu111_rfsoc_trd_i/mts_clk/clk_wiz_1/inst/mmcme4_adv_inst/CLKOUT2]
create_generated_clock -name mmcm_clkout0 [get_pins zcu111_rfsoc_trd_i/ddr4_0/inst/u_ddr4_infrastructure/gen_mmcme4.u_mmcme_adv_inst/CLKOUT0]

set_clock_groups -name asy_grp1 -asynchronous -group [get_clocks clk_pl_0] -group [get_clocks RFDAC0_CLK] -group [get_clocks RFDAC1_CLK] -group [get_clocks -of_objects [get_pins zcu111_rfsoc_trd_i/clk_block/ADC_clk_wiz_*/inst/plle4_adv_inst/CLKOUT0]] -group [get_clocks mts_clk_pl_clk_dac] -group [get_clocks pl_clk_adc_1] -group [get_clocks clk_out3_zcu111_rfsoc_trd_clk_wiz_1_0] -group [get_clocks clk_out3_zcu111_rfsoc_trd_clk_wiz_0_0]
set_clock_groups -name asy_grp2 -asynchronous -group [get_clocks RFDAC0_CLK] -group [get_clocks RFDAC1_CLK] -group [get_clocks clk_pl_0] -group [get_clocks -of_objects [get_pins zcu111_rfsoc_trd_i/clk_block/ADC_clk_wiz_*/inst/plle4_adv_inst/CLKOUT0]] -group [get_clocks mts_clk_pl_dac_clk_45] -group [get_clocks mts_clk_pl_adc_clk_45] -group [get_clocks clk_out3_zcu111_rfsoc_trd_clk_wiz_0_0] -group [get_clocks clk_out3_zcu111_rfsoc_trd_clk_wiz_1_0]
set_clock_groups -name asy_grp3 -asynchronous -group [get_clocks clk_pl_0] -group [get_clocks mmcm_clkout0]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins zcu111_rfsoc_trd_i/clk_block/ADC_clk_wiz_0/inst/plle4_adv_inst/CLKOUT0]] -group [get_clocks -of_objects [get_pins zcu111_rfsoc_trd_i/clk_block/ADC_clk_wiz_1/inst/plle4_adv_inst/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins zcu111_rfsoc_trd_i/clk_block/ADC_clk_wiz_0/inst/plle4_adv_inst/CLKOUT0]] -group [get_clocks -of_objects [get_pins zcu111_rfsoc_trd_i/clk_block/ADC_clk_wiz_2/inst/plle4_adv_inst/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins zcu111_rfsoc_trd_i/clk_block/ADC_clk_wiz_0/inst/plle4_adv_inst/CLKOUT0]] -group [get_clocks -of_objects [get_pins zcu111_rfsoc_trd_i/clk_block/ADC_clk_wiz_3/inst/plle4_adv_inst/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins zcu111_rfsoc_trd_i/clk_block/ADC_clk_wiz_1/inst/plle4_adv_inst/CLKOUT0]] -group [get_clocks -of_objects [get_pins zcu111_rfsoc_trd_i/clk_block/ADC_clk_wiz_0/inst/plle4_adv_inst/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins zcu111_rfsoc_trd_i/clk_block/ADC_clk_wiz_2/inst/plle4_adv_inst/CLKOUT0]] -group [get_clocks -of_objects [get_pins zcu111_rfsoc_trd_i/clk_block/ADC_clk_wiz_0/inst/plle4_adv_inst/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins zcu111_rfsoc_trd_i/clk_block/ADC_clk_wiz_3/inst/plle4_adv_inst/CLKOUT0]] -group [get_clocks -of_objects [get_pins zcu111_rfsoc_trd_i/clk_block/ADC_clk_wiz_0/inst/plle4_adv_inst/CLKOUT0]]


set_property CLOCK_DELAY_GROUP MTS_ADC [get_nets -of_objects [get_pins zcu111_rfsoc_trd_i/mts_clk/clk_wiz_0/inst/clk_out1]]
set_property CLOCK_DELAY_GROUP MTS_ADC [get_nets -of_objects [get_pins zcu111_rfsoc_trd_i/mts_clk/clk_wiz_0/inst/clk_out2]]
set_property CLOCK_DELAY_GROUP MTS_ADC [get_nets -of_objects [get_pins zcu111_rfsoc_trd_i/mts_clk/clk_wiz_0/inst/clk_out3]]

set_property CLOCK_DELAY_GROUP MTS_DAC [get_nets -of_objects [get_pins zcu111_rfsoc_trd_i/mts_clk/clk_wiz_1/inst/clk_out1]]
set_property CLOCK_DELAY_GROUP MTS_DAC [get_nets -of_objects [get_pins zcu111_rfsoc_trd_i/mts_clk/clk_wiz_1/inst/clk_out2]]
set_property CLOCK_DELAY_GROUP MTS_DAC [get_nets -of_objects [get_pins zcu111_rfsoc_trd_i/mts_clk/clk_wiz_1/inst/clk_out3]]


# false path constraints for the adc sync1,sync2 through sync8 outputs blocks
set_false_path -from [get_pins {zcu111_rfsoc_trd_i/clk_block/adc_sync/sync_1/inst/xpm_cdc_single_inst/syncstages_ff_reg[*]/C}]
set_false_path -from [get_pins {zcu111_rfsoc_trd_i/clk_block/adc_sync/sync_2/inst/xpm_cdc_single_inst/syncstages_ff_reg[*]/C}]
set_false_path -from [get_pins {zcu111_rfsoc_trd_i/clk_block/adc_sync/sync_3/inst/xpm_cdc_single_inst/syncstages_ff_reg[*]/C}]
set_false_path -from [get_pins {zcu111_rfsoc_trd_i/clk_block/adc_sync/sync_4/inst/xpm_cdc_single_inst/syncstages_ff_reg[*]/C}]
set_false_path -from [get_pins {zcu111_rfsoc_trd_i/clk_block/adc_sync/sync_5/inst/xpm_cdc_single_inst/syncstages_ff_reg[*]/C}]
set_false_path -from [get_pins {zcu111_rfsoc_trd_i/clk_block/adc_sync/sync_6/inst/xpm_cdc_single_inst/syncstages_ff_reg[*]/C}]
set_false_path -from [get_pins {zcu111_rfsoc_trd_i/clk_block/adc_sync/sync_7/inst/xpm_cdc_single_inst/syncstages_ff_reg[*]/C}]
set_false_path -from [get_pins {zcu111_rfsoc_trd_i/clk_block/adc_sync/sync_8/inst/xpm_cdc_single_inst/syncstages_ff_reg[*]/C}]


set_property ASYNC_REG false [get_cells {zcu111_rfsoc_trd_i/*/*/sync_*/inst/xpm_cdc_single_inst/syncstages_ff_reg[*]}]


set_max_delay -from [get_clocks mts_clk_pl_clk_dac] -to [get_clocks mts_clk_pl_dac_clk_45] 3.5
set_max_delay -from [get_clocks pl_clk_adc_1] -to [get_clocks mts_clk_pl_adc_clk_45] 2.1

set_property CLOCK_DELAY_GROUP HoldGroup1 [get_nets { zcu111_rfsoc_trd_i/mts_clk/clk_wiz_1/inst/clk_out1  zcu111_rfsoc_trd_i/mts_clk/clk_wiz_1/inst/clk_out2 }]