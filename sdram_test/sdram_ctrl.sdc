# This file is generated by Anlogic Timing Wizard. 04 11 2020

#Created Clock
create_clock -name clk_24m -period 41.67 -waveform {0 20.835} [get_ports {i_clk_24m}]

#Created Generated Clock
create_generated_clock  -name clk_168m_ctrl -source [get_ports {i_clk_24m}] -multiply_by 7 [get_nets {sdram_ctrl_clk}]
create_generated_clock  -name clk_168m_phy -source [get_ports {i_clk_24m}] -multiply_by 7 [get_nets {sdram_phy_clk}]

#Set Clock Uncertainty
set_clock_uncertainty 0.2  [get_clocks {clk_24m}]
