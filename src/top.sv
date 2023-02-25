module top
(
    input   wire logic          I_clk           , //27Mhz
    input   wire logic          I_rst_n         ,
    // LEDS
    output       logic [4:0]    O_led           , 
     //HDMI
//    output       logic          O_tmds_clk_p    ,
//    output       logic          O_tmds_clk_n    ,
//    output       logic [2:0]    O_tmds_data_p   ,//{r,g,b}
//    output       logic [2:0]    O_tmds_data_n   ,
     //ULPI
//    input   wire logic          I_ulpi_clk      ,// 60MHz xlk from PHY
//    input   wire logic          I_ulpi_nxt      ,
//    input   wire logic          I_ulpi_dir      ,
//    output       logic          O_ulpi_rst      ,
//    output       logic          O_ulpi_stp      ,
//    inout   wire logic [7:0]   IO_ulpi_data     ,
    // UART
    output       logic          O_uart_tx       ,
    input   wire logic          I_uart_rx       ,
    // Buttons
    input   wire logic [3:0]    I_button	,
    // DDR3
    output       logic [13-1:0] O_ddr_addr,       //ROW_WIDTH=14
    output       logic [3-1:0]  O_ddr_bank,       //BANK_WIDTH=3
    output       logic          O_ddr_cs,
    output       logic          O_ddr_ras,
    output       logic          O_ddr_cas,
    output       logic          O_ddr_we,
    output       logic          O_ddr_ck,
    output       logic          O_ddr_ck_n,
    output       logic          O_ddr_cke,
    output       logic          O_ddr_odt,
    output       logic          O_ddr_reset_n,
    output       logic [2-1:0]  O_ddr_dm,         //DM_WIDTH=2
    inout   wire logic [16-1:0] IO_ddr_dq,         //DQ_WIDTH=16
    inout   wire logic [2-1:0]  IO_ddr_dqs,        //DQS_WIDTH=2
    inout   wire logic [2-1:0]  IO_ddr_dqs_n      //DQS_WIDTH=2
);


    wire mem_clk_400MHz;
    wire mem_clk_200MHz;
    wire mem_intf_clk;
    wire mem_pll_lock;

    MEM_rPLL mem_pll_inst (
        .clkout(mem_clk_400MHz), //output clkout
        .lock(mem_pll_lock), //output lock
        .clkoutd(mem_clk_200MHz), //output clkoutd
        .clkin(I_clk) //input clkin
    );

    wire sys_clk_150MHz;
    wire sys_clk_75MHz;
    wire sys_clk_50MHz;
    wire sys_clk_lock;

    SYS_rPLL sys_pll_inst (
        .clkout(sys_clk_150MHz), //output clkout
        .lock(sys_clk_lock), //output lock
        .clkoutd(sys_clk_75MHz), //output clkoutd
        .clkoutd3(sys_clk_50MHz), //output clkoutd3
        .clkin(I_clk) //input clkin
    );


    logic   [5:0] mem_burst_count;                                  // How many 128 bit chunks to burst.
    logic         mem_burst_mode = 1'b1;                            // ...?  Should always be 1 I think.
    logic         mem_cmd_rdy, mem_cmd_en;                          // DDR command interface
    logic   [2:0] mem_cmd;                                          // DDR command interface
    logic         mem_rd_data_val, mem_rd_data_end;                 // DDR Read interface
    logic         mem_wr_data_en, mem_wr_data_end, mem_wr_data_rdy; // DDR Write interface
    logic  [26:0] mem_addr;                                         // 27 bit DDR address 
    logic [127:0] mem_tmp_data;                                     // Tmp storage...
    logic [127:0] mem_wr_data;                                      // DDR Write inteface
    logic  [15:0] mem_wr_data_mask;                                 // DDR Write interface (one bit per byte)
    logic [127:0] mem_rd_data;                                      // DDR Read inteface
    logic         mem_calib_complete;                               // DDR Calibration complete.

	DDR3_Memory_Interface_Top mem_intf (
		.memory_clk(mem_clk_200MHz), //input memory_clk
		.clk(sys_clk_75MHz), //input clk
		.pll_lock(mem_pll_lock & sys_clk_lock), //input pll_lock
		.rst_n(I_rst_n), //input rst_n
		.app_burst_number(mem_burst_count), //input [5:0] app_burst_number
		.cmd_ready(mem_cmd_rdy), //output cmd_ready
		.cmd(mem_cmd), //input [2:0] cmd
		.cmd_en(mem_cmd_en), //input cmd_en
		.addr(mem_addr), //input [26:0] addr
		.wr_data_rdy(mem_wr_data_rdy), //output wr_data_rdy
		.wr_data(mem_wr_data), //input [127:0] wr_data
		.wr_data_en(mem_wr_data_en), //input wr_data_en
		.wr_data_end(mem_wr_data_end), //input wr_data_end
		.wr_data_mask(mem_wr_data_mask), //input [15:0] wr_data_mask
		.rd_data(mem_rd_data), //output [127:0] rd_data
		.rd_data_valid(mem_rd_data_val), //output rd_data_valid
		.rd_data_end(mem_rd_data_end), //output rd_data_end
		.sr_req(1'b0), //input sr_req
		.ref_req(1'b0), //input ref_req
		.sr_ack(), //output sr_ack
		.ref_ack(), //output ref_ack
		.init_calib_complete(mem_calib_complete), //output init_calib_complete
		.clk_out(mem_intf_clk), //output clk_out
		.ddr_rst(), //output ddr_rst
		.burst(mem_burst_mode), //input burst
		.O_ddr_addr(O_ddr_addr), //output [12:0] O_ddr_addr
		.O_ddr_ba(O_ddr_bank), //output [2:0] O_ddr_ba
		.O_ddr_cs_n(O_ddr_cs), //output O_ddr_cs_n
		.O_ddr_ras_n(O_ddr_ras), //output O_ddr_ras_n
		.O_ddr_cas_n(O_ddr_cas), //output O_ddr_cas_n
		.O_ddr_we_n(O_ddr_we), //output O_ddr_we_n
		.O_ddr_clk(O_ddr_ck), //output O_ddr_clk
		.O_ddr_clk_n(O_ddr_ck_n), //output O_ddr_clk_n
		.O_ddr_cke(O_ddr_cke), //output O_ddr_cke
		.O_ddr_odt(O_ddr_odt), //output O_ddr_odt
		.O_ddr_reset_n(O_ddr_reset_n), //output O_ddr_reset_n
		.O_ddr_dqm(O_ddr_dm), //output [1:0] O_ddr_dqm
		.IO_ddr_dq(IO_ddr_dq), //inout [15:0] IO_ddr_dq
		.IO_ddr_dqs(IO_ddr_dqs), //inout [1:0] IO_ddr_dqs
		.IO_ddr_dqs_n(IO_ddr_dqs_n) //inout [1:0] IO_ddr_dqs_n
	);
    
    logic [127:0] mem_rd_fifo_wr_data;
    logic         mem_rd_fifo_wr_data_en;
    logic   [4:0] mem_rd_fifo_wr_data_num;
    
    logic   [7:0] mem_rd_fifo_rd_data;
    logic         mem_rd_fifo_rd_data_en;
    logic   [8:0] mem_rd_fifo_rd_data_num;
    
    logic         mem_rd_fifo_full;
    logic         mem_rd_fifo_empty;
    
    assign mem_rd_fifo_wr_data = mem_rd_data;
    
	READ_FIFO_HS_Top read_fifo_inst (
		.Data(mem_rd_fifo_wr_data), //input [127:0] Data
		.Reset(!mem_calib_complete), //input Reset
		.WrClk(mem_intf_clk), //input WrClk
		.RdClk(sys_clk_75MHz), //input RdClk
		.WrEn(mem_rd_fifo_wr_data_en), //input WrEn
		.RdEn(mem_rd_fifo_rd_data_en), //input RdEn
		.Wnum(mem_rd_fifo_wr_data_num), //output [4:0] Wnum
		.Rnum(mem_rd_fifo_rd_data_num), //output [8:0] Rnum
		.Q(mem_rd_fifo_rd_data), //output [7:0] Q
		.Empty(mem_rd_fifo_empty), //output Empty
		.Full(mem_rd_fifo_full) //output Full
	);

    logic   [7:0] mem_wr_fifo_wr_data;
    logic         mem_wr_fifo_wr_data_en;
    logic   [8:0] mem_wr_fifo_wr_data_num;
    
    logic [127:0] mem_wr_fifo_rd_data;
    logic         mem_wr_fifo_rd_data_en;
    logic   [4:0] mem_wr_fifo_rd_data_num;
    
    logic         mem_wr_fifo_full;
    logic         mem_wr_fifo_empty;
    
    assign mem_wr_data = mem_wr_fifo_rd_data;

	WRITE_FIFO_HS_Top write_fifo_inst (
		.Data(mem_wr_fifo_wr_data), //input [7:0] Data
		.Reset(!mem_calib_complete), //input Reset
		.WrClk(sys_clk_75MHz), //input WrClk
		.RdClk(mem_intf_clk), //input RdClk
		.WrEn(mem_wr_fifo_wr_data_en), //input WrEn
		.RdEn(mem_wr_fifo_rd_data_en), //input RdEn
		.Wnum(mem_wr_fifo_wr_data_num), //output [8:0] Wnum
		.Rnum(mem_wr_fifo_rd_data_num), //output [4:0] Rnum
		.Q(mem_wr_fifo_rd_data), //output [127:0] Q
		.Empty(mem_wr_fifo_empty), //output Empty
		.Full(mem_wr_fifo_full) //output Full
	);

    logic [7:0] tmp;

    ///// Print stuff 
//    `include "print.v"
//    defparam tx.uart_freq=115200;
//    defparam tx.clk_freq=27_000_000;
//    assign print_clk = I_clk;
//    assign txp = O_uart_tx;


    assign O_led[0] = ~sys_clk_50MHz;
    assign O_led[1] = ~sys_clk_75MHz;
    assign O_led[2] = ~sys_clk_150MHz;
    assign O_led[3] = ~mem_intf_clk;
    assign O_led[4] = ~mem_clk_200MHz;

    assign mem_wr_fifo_wr_data = mem_rd_fifo_rd_data;

    /////  sys_clk domain
    always_ff @(posedge sys_clk_75MHz or negedge I_rst_n)
    begin
        if (!I_rst_n)
        begin
            // Initialize read side of read fifo.
            mem_rd_fifo_rd_data_en <= 0;

            // Initialize write side of write fifo.
            mem_wr_fifo_wr_data_en <= 0;
//            mem_wr_fifo_wr_data    <= 0;
            
        end
        else if (mem_calib_complete)
        begin
            
        end
    end

    /////  mem_intf_clk domain
    always_ff @(posedge mem_intf_clk or negedge I_rst_n)
    begin
        if (!I_rst_n)
        begin
            // Initialize write side of the read fifo.
            mem_rd_fifo_wr_data_en <= 0;
            
            // Initialize read side of write fifo.
            mem_wr_fifo_rd_data_en <= 0;

            // Initialize DDR inteface
            mem_addr               <= 0;
            mem_burst_count        <= 1;
            mem_burst_mode         <= 1; // I think this needs to always be 1.
            mem_cmd                <= 0;
            mem_cmd_en             <= 0;
            mem_wr_data_en         <= 0;
            mem_wr_data_end        <= 0;
            mem_wr_data_mask       <= 16'hffff; // Don't mask...

        end
        else if (mem_calib_complete)
            //`print("Init Complete\n",STR);
        begin
        end
    end


endmodule