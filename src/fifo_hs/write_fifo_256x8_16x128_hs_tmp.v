//Copyright (C)2014-2022 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: GowinSynthesis V1.9.8.10
//Part Number: GW2A-LV18PG256C8/I7
//Device: GW2A-18
//Device Version: C
//Created Time: Fri Feb 24 23:46:39 2023

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	WRITE_FIFO_HS_Top your_instance_name(
		.Data(Data_i), //input [7:0] Data
		.Reset(Reset_i), //input Reset
		.WrClk(WrClk_i), //input WrClk
		.RdClk(RdClk_i), //input RdClk
		.WrEn(WrEn_i), //input WrEn
		.RdEn(RdEn_i), //input RdEn
		.Wnum(Wnum_o), //output [8:0] Wnum
		.Rnum(Rnum_o), //output [4:0] Rnum
		.Q(Q_o), //output [127:0] Q
		.Empty(Empty_o), //output Empty
		.Full(Full_o) //output Full
	);

//--------Copy end-------------------
