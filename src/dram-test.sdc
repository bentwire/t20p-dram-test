//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8.10 
//Created Time: 2023-03-02 22:45:49
create_clock -name mem_intf_clk -period 20 -waveform {0 5} [get_nets {mem_intf_clk}] -add
create_clock -name I_fifo_clk -period 16.667 -waveform {0 8.334} [get_ports {I_fifo_clk}] -add
create_clock -name sys_clk -period 13.333 -waveform {0 6.667} [get_nets {sys_clk}] -add
create_clock -name I_clk -period 37.037 -waveform {0 18.518} [get_ports {I_clk}] -add
create_generated_clock -name mem_clk_200MHz -source [get_ports {I_clk}] -master_clock I_clk -divide_by 8 -multiply_by 59 -add [get_nets {mem_clk_200MHz}]
create_generated_clock -name mem_clk_400MHz -source [get_ports {I_clk}] -master_clock I_clk -divide_by 4 -multiply_by 59 -add [get_nets {mem_pll_inst/mem_clk_400MHz}]
create_generated_clock -name O_sys_clk_150MHz -source [get_ports {I_clk}] -master_clock I_clk -divide_by 9 -multiply_by 50 -duty_cycle 50 -add [get_nets {O_sys_clk_150MHz}]
create_generated_clock -name sys_clk_75MHz -source [get_ports {I_clk}] -master_clock I_clk -divide_by 9 -multiply_by 25 -add [get_nets {sys_clk_75MHz}]
set_clock_groups -asynchronous -group [get_clocks {mem_clk_400MHz mem_clk_200MHz}] -group [get_clocks {O_sys_clk_150MHz sys_clk_75MHz}] -group [get_clocks {sys_clk}] -group [get_clocks {mem_intf_clk}]
