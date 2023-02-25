//Copyright (C)2014-2022 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.8.10
//Part Number: GW2A-LV18PG256C8/I7
//Device: GW2A-18
//Device Version: C
//Created Time: Fri Feb 24 17:51:16 2023

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    SYS_rPLL your_instance_name(
        .clkout(clkout_o), //output clkout
        .lock(lock_o), //output lock
        .clkoutd(clkoutd_o), //output clkoutd
        .clkoutd3(clkoutd3_o), //output clkoutd3
        .clkin(clkin_i) //input clkin
    );

//--------Copy end-------------------
