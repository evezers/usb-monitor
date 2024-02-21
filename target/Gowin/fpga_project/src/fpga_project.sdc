//Copyright (C)2014-2024 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8.11 Education
//Created Time: 2024-01-29 10:31:12
create_clock -name ulpi_clk -period 16.667 -waveform {0 8.334} [get_ports {ulpi_clk}]
create_clock -name lcd_clk -period 20 -waveform {0 10} [get_ports {lcd_clk}]
create_clock -name clk -period 40 -waveform {0 20} [get_ports {clk}]
