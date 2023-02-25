//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8.10 
//Created Time: 2023-02-24 23:24:39
create_clock -name I_clk -period 37.037 -waveform {0 18.518} [get_ports {I_clk}]
create_generated_clock -name sys_clk_75MHz -source [get_nets {sys_clk_150MHz}] -master_clock sys_clk_150MHz -divide_by 2 [get_nets {sys_clk_75MHz}]
create_generated_clock -name sys_clk_50MHz -source [get_nets {sys_clk_150MHz}] -master_clock sys_clk_150MHz -divide_by 3 [get_nets {sys_clk_50MHz}]
create_generated_clock -name sys_clk_150MHz -source [get_ports {I_clk}] -master_clock I_clk -divide_by 9 -multiply_by 50 [get_nets {sys_clk_150MHz}]
create_generated_clock -name mem_clk_400MHz -source [get_ports {I_clk}] -master_clock I_clk -divide_by 4 -multiply_by 59 [get_nets {mem_pll_inst/mem_clk_400MHz}]
create_generated_clock -name mem_clk_200MHz -source [get_ports {I_clk}] -master_clock I_clk -divide_by 8 -multiply_by 59 [get_nets {mem_clk_200MHz}]
