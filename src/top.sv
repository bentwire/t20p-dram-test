module top
(
    ///////// Clks and reset
    input   wire logic          I_clk           , //27Mhz
    input   wire logic          I_aux_clk,
    input   wire logic          I_rst_n         ,
    output       logic          O_sys_clk_150MHz,
//    output       logic          O_sys_clk_75MHz,
//    output       logic          O_sys_clk_50MHz,
     //////// LEDS
    output       logic [4:0]    O_led           , 
     //HDMI
//    output       logic          O_tmds_clk_p    ,
//    output       logic          O_tmds_clk_n    ,
//    output       logic [2:0]    O_tmds_data_p   ,//{r,g,b}
//    output       logic [2:0]    O_tmds_data_n   ,
     //////// ULPI
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
    input   wire logic [3:0]    I_button,
    // Switches
    input   wire logic [3:0]    I_switch,
    // FT245H SYNC FIFO
    input   wire logic          I_fifo_clk,     // 60MHz clock
    input   wire logic          I_fifo_rxf_n,   // RX Full
    input   wire logic          I_fifo_txe_n,   // TX Empty
    output       logic          O_fifo_rd_n,    // Read Enable
    output       logic          O_fifo_wr_n,    // Write Enable
    output       logic          O_fifo_oe_n,    // Output Enable
    inout   wire logic    [7:0] IO_fifo_data,   // Data
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
    wire sys_clk;
    wire sys_clk_lock;

    SYS_rPLL sys_pll_inst (
        .clkout(sys_clk_150MHz), //output clkout
        .lock(sys_clk_lock), //output lock
        .clkoutd(sys_clk_75MHz), //output clkoutd
        .clkoutd3(sys_clk_50MHz), //output clkoutd3
        .clkin(I_clk) //input clkin
    );

    Gowin_DCS sys_clk_dcs_inst (
        .clkout(sys_clk), //output clkout
        .clksel(I_switch), //input [3:0] clksel
        .clk0(I_fifo_clk), //input clk0
        .clk1(sys_clk_150MHz), //input clk1
        .clk2(sys_clk_75MHz), //input clk2
        .clk3(sys_clk_50MHz) //input clk3
    );

//    assign sys_clk          = sys_clk_50MHz;
    assign O_sys_clk_150MHz = sys_clk_150MHz;
//    assign O_sys_clk_75MHz  = sys_clk_75MHz;
//    assign O_sys_clk_50MHz  = sys_clk_50MHz;

    logic   [5:0] mem_burst_count;                                  // How many 128 bit chunks to burst.
    logic         mem_burst_mode = 1'b1;                            // ...?  Should always be 1 I think.
    logic         mem_cmd_rdy, mem_cmd_en;                          // DDR command interface
    logic   [2:0] mem_cmd;                                          // DDR command interface
    logic         mem_rd_data_val, mem_rd_data_end;                 // DDR Read interface
    logic         mem_wr_data_en, mem_wr_data_end, mem_wr_data_rdy; // DDR Write interface
    logic  [26:0] mem_addr;                                         // 27 bit DDR address 
    logic         mem_wr_req;                                       // Request Write
    logic         mem_wr_req_ack;                                   // Request Write Ack
    logic  [26:0] mem_wr_req_addr;                                  // 27 bit DDR address 
    logic         mem_rd_req;                                       // Request Read
    logic         mem_rd_req_ack;                                   // Request Read Ack
    logic  [26:0] mem_rd_req_addr;                                  // 27 bit DDR address 
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
    
    //assign mem_rd_fifo_wr_data = mem_rd_data;
    
	READ_FIFO_HS_Top read_fifo_inst (
		.Data(mem_rd_fifo_wr_data), //input [127:0] Data
		.Reset(!mem_calib_complete), //input Reset
		.WrClk(mem_intf_clk), //input WrClk
		.RdClk(sys_clk), //input RdClk
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
    
    //assign mem_wr_data = mem_wr_fifo_rd_data;

	WRITE_FIFO_HS_Top write_fifo_inst (
		.Data(mem_wr_fifo_wr_data), //input [7:0] Data
		.RdReset(!mem_calib_complete), //input Reset
        .WrReset(!sys_clk_lock), //input Reset
		.WrClk(sys_clk), //input WrClk
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


//    assign O_led[0] = ~mem_pll_lock;
//    assign O_led[1] = ~sys_clk_lock;
//    assign O_led[2] = ~mem_calib_complete;
//    assign O_led[3] = ~mem_intf_clk;
//    assign O_led[4] = ~sys_clk;

//    assign O_led = ~mem_wr_fifo_rd_data_num;
    // Some stuff for the test data
    logic [7:0] test_data_out;
    logic [7:0] test_data_in;
    logic [7:0] test_data_addr;
    logic       test_data_we;
    logic       test_data_oe;

    RAM256x8_SP your_instance_name(
        .dout(test_data_out), //output [7:0] dout
        .clk(sys_clk), //input clk
        .oce(test_data_oe), //input oce
        .ce(1'b1), //input ce
        .reset(I_rst_n), //input reset
        .wre(test_data_we), //input wre
        .ad(test_data_addr), //input [7:0] ad
        .din(test_data_in) //input [7:0] din
    );

    logic [4:0] state;
    assign O_led = ~state;

    //assign mem_wr_fifo_wr_data = mem_rd_fifo_rd_data;
    logic [7:0] fifo_wr_data;
    logic       test_error;
    logic [1:0] mem_wr_ack; // edge detect;
    logic [1:0] mem_rd_ack; // edge detect;
    enum { SYS_IDLE, SYS_MEM_TEST_START, SYS_CALC_TEST_DATA, SYS_WRITE_TEST_DATA, SYS_WAIT_WRITE_ACK, SYS_CHECK_TEST_DATA, SYS_REPORT_RESULTS, SYS_MEM_TEST_DONE } sys_state;
    /////  sys_clk domain
    always_ff @(posedge sys_clk or negedge I_rst_n)
    begin
        if (!I_rst_n)
        begin
             //////Initialize read side of read fifo.
            mem_rd_fifo_rd_data_en <= 0;

             //////Initialize write side of write fifo.
            mem_wr_fifo_wr_data_en <= 0;
             //////Disale FT232H Fifo.
            O_fifo_wr_n            <= 1'b1;
            O_fifo_rd_n            <= 1'b1;
            O_fifo_oe_n            <= 1'b1;
            mem_wr_fifo_wr_data    <= 0;

             //////Test stuff
//            test_data_data         <= {8'h00, 8'h00};
            test_data_addr         <= 0;
            ////// Memory interface
            mem_rd_req             <= 0;
            mem_rd_req_addr        <= 0;
            mem_wr_req             <= 0;
            mem_wr_req_addr        <= 0;
            ////// Edge detection for ACK coming from mem clk domain
            mem_wr_ack             <= 2'b0;
            mem_rd_ack             <= 2'b0;
            ////// State machine...
            sys_state              <= SYS_IDLE;
        end
        else if (mem_calib_complete)
        begin
            mem_wr_ack[0] <= mem_wr_req_ack;
            mem_wr_ack[1] <= mem_wr_ack[0];
            mem_rd_ack[0] <= mem_rd_req_ack;
            mem_rd_ack[1] <= mem_rd_ack[0];

            case (sys_state)
                SYS_IDLE:
                begin
                    state <= 0;
                    mem_wr_fifo_wr_data_en <= 0;
                    O_fifo_wr_n            <= 1'b1;
                    O_fifo_rd_n            <= 1'b1;
                    sys_state              <= SYS_MEM_TEST_START;
                end
                SYS_MEM_TEST_START:
                begin
                    state <= 1;
                    //mem_rd_req_addr        <= mem_rd_req_addr + 26'd256;
                    //mem_wr_req_addr        <= mem_wr_req_addr + 27'd256;
                    mem_wr_req             <= 0;
                    mem_rd_req             <= 0;

//                    test_data_data         <= {8'h00, 8'h00};
                    test_data_addr         <= 0;
//                    if (!mem_wr_fifo_full)
                    sys_state              <= SYS_CALC_TEST_DATA;
                    test_data_we           <= 1'b1;
                end
                SYS_CALC_TEST_DATA:
                begin
                    state <= 2;
//                    test_data_data[0]         <= test_data_data[1];
//                    test_data_data[1]         <= test_data_addr;
                    test_data_addr            <= test_data_addr + 8'b01;
//                    test_data[test_data_addr] <= test_data_addr; //test_data_data[0] ^ test_data_data[1];

                    if (test_data_addr == 8'hff) 
                    begin
                        test_data_addr         <= 0;
                        mem_wr_fifo_wr_data_en <= 1'b1;
                        O_fifo_wr_n            <= 1'b0;
                        test_data_we           <= 1'b0;
                        test_data_oe           <= 1'b1;
                        sys_state              <= SYS_WRITE_TEST_DATA;
                    end
//                    sys_state <= SYS_WRITE_TEST_DATA;
                end
                SYS_WRITE_TEST_DATA:
                begin
                    //O_fifo_wr_n <= 1'b0;
                    state <= 4;
                    test_data_addr <= test_data_addr + 8'b01;
                    if (test_data_addr == 8'hff) 
                    begin
                        mem_wr_fifo_wr_data_en <= 1'b0;
                        test_data_oe           <= 1'b0;
                        O_fifo_wr_n <= 1'b1;
                        mem_rd_fifo_rd_data_en <= 1'b0;
                        test_data_addr         <= 0;
                        mem_wr_req             <= 1'b1;
                        sys_state              <= SYS_WAIT_WRITE_ACK;
                    end
//                    sys_state <= SYS_IDLE;
                end
                SYS_WAIT_WRITE_ACK:
                begin
                    state <= 8;
                    //mem_wr_req <= 1'b0;
                    if (mem_wr_ack[0] & !mem_wr_ack[1]) // Ack rising edge.
                    begin
                        mem_wr_req             <= 1'b0;
//                        mem_rd_req             <= 1'b1;
                        sys_state              <= SYS_IDLE;
                    end
                end
                SYS_CHECK_TEST_DATA:
                begin
                    if (mem_rd_ack[0] & !mem_rd_ack[1])
                    begin
                        mem_rd_req             <= 1'b0;
                        mem_rd_fifo_rd_data_en <= 1'b1;
                        test_data_addr         <= test_data_addr + 8'b01;
                        if (test_data_addr == 8'hff) 
                        begin
                            mem_rd_fifo_rd_data_en <= 1'b0;
                            test_data_addr         <= 0;
                            sys_state              <= SYS_IDLE;
                        end
                    end
                end
                SYS_REPORT_RESULTS:
                begin
                end
                SYS_MEM_TEST_DONE:
                begin
                end
            endcase
        end
    end

    assign IO_fifo_data = O_fifo_wr_n ? 8'bz : fifo_wr_data;
    assign test_data_in = sys_state == SYS_CALC_TEST_DATA ? test_data_addr : 8'bz;
//    assign mem_wr_fifo_wr_data = sys_state == SYS_WRITE_TEST_DATA ? test_data[test_data_addr] : 8'b0;
    always_comb
    begin
        unique case (sys_state)
            SYS_IDLE:
            begin
                test_error = 1'b0;
                mem_wr_fifo_wr_data = 8'bz;
                fifo_wr_data = 0;
            end
            SYS_MEM_TEST_START:
            begin
                test_error = 1'b0;
                mem_wr_fifo_wr_data = 8'bz;
                fifo_wr_data = 0;
            end
            SYS_CALC_TEST_DATA:
            begin
                test_error = 1'b0;
                mem_wr_fifo_wr_data = 8'bz;
                fifo_wr_data = 0;
//                test_data_in = test_data_addr;
            end
            SYS_WRITE_TEST_DATA:
            begin
                test_error = 1'b0;
                mem_wr_fifo_wr_data = test_data_out;
                fifo_wr_data = test_data_out;
            end
            SYS_WAIT_WRITE_ACK:
            begin
                test_error = 1'b0;
                mem_wr_fifo_wr_data = 8'bz;
                fifo_wr_data = 8'bz;
            end
            SYS_CHECK_TEST_DATA:
            begin
                test_error = 1'b0;
//                test_error = (mem_rd_fifo_rd_data == test_data[test_data_addr]) ? 1'b0 : 1'b1;
                mem_wr_fifo_wr_data = 8'bz;
                fifo_wr_data = 8'bz;
            end
            SYS_REPORT_RESULTS:
            begin
                test_error = 1'b0;
                mem_wr_fifo_wr_data = 8'bz;
                fifo_wr_data = 8'bz;
            end
            SYS_MEM_TEST_DONE:
            begin
                test_error = 1'b0;
                mem_wr_fifo_wr_data = 8'bz;
                fifo_wr_data = 8'bz;
            end
            default:
            begin
                test_error = 1'b0;
                mem_wr_fifo_wr_data = 8'bz;
                fifo_wr_data = 8'bz;
            end
        endcase
    end

    logic [1:0] mem_rd_req_e;
    logic [1:0] mem_wr_req_e;
    enum { MEM_IDLE, MEM_WRITE_REQ, MEM_WRITE, MEM_WRITE_COMP, MEM_READ_REQ, MEM_READ, MEM_READ_COMP } mem_state;
    /////  mem_intf_clk domain
    always_ff @(posedge mem_intf_clk or negedge I_rst_n)
    begin
        if (!I_rst_n)
        begin
            // Initialize write side of the read fifo.
//            mem_rd_fifo_wr_data_en <= 0;
            
            // Initialize read side of write fifo.
//            mem_wr_fifo_rd_data_en <= 0;

            // Initialize DDR inteface
            mem_addr               <= 0;
            mem_burst_count        <= 1;
            mem_burst_mode         <= 1; // I think this needs to always be 1.
            mem_cmd                <= 0;
            mem_cmd_en             <= 0;
//            mem_wr_data_en         <= 0;
//            mem_wr_data_end        <= 0;
            mem_wr_data_mask       <= 16'hffff; // Don't mask...
            mem_rd_req_ack         <= 0;
            mem_wr_req_ack         <= 0;
            mem_rd_req_e           <= 0;
            mem_wr_req_e           <= 0;
            mem_state              <= MEM_IDLE;
        end
        else if (mem_calib_complete)
        begin
            mem_rd_req_e[0]        <= mem_rd_req;
            mem_rd_req_e[1]        <= mem_rd_req_e[0];
            mem_wr_req_e[0]        <= mem_wr_req;
            mem_wr_req_e[1]        <= mem_wr_req_e[0];
            //`print("Init Complete\n",STR);

            case (mem_state)
                MEM_IDLE:
                begin
                    mem_rd_req_ack         <= 1'b0;
                    mem_wr_req_ack         <= 1'b0;
                    mem_cmd_en             <= 1'b0;
//                    mem_rd_fifo_wr_data_en <= 0;

                    if (mem_rd_req_e[0] & !mem_rd_req_e[1]) // Read request rising edge.
                    begin
                        mem_addr  <= mem_rd_req_addr;
                        mem_state <= MEM_READ_REQ;
                    end
                    else if (mem_wr_req_e[0] & !mem_wr_req_e[1])
                    begin
                        mem_addr  <= mem_wr_req_addr;
                        mem_state <= MEM_WRITE_REQ;
                    end
                end
                MEM_READ_REQ:
                begin
                    if (mem_cmd_rdy)
                    begin
                        // Send read command and go to next state
                        mem_cmd    <= 3'b001;
                        mem_cmd_en <= 1'b1;
                        mem_state  <= MEM_READ;
                    end
                end
                MEM_READ:
                begin
                    mem_cmd_en <= 1'b0;
                    if (mem_rd_fifo_empty)
                        mem_state <= MEM_READ_COMP;
                end
                MEM_READ_COMP:
                begin
                    mem_rd_req_ack <= 1'b1;
                    mem_state      <= MEM_IDLE;
                end
                MEM_WRITE_REQ:
                begin
                    if (mem_cmd_rdy)
                    begin
                        mem_cmd                <= 3'b000;
                        mem_cmd_en             <= 1'b1;
//                        mem_wr_fifo_rd_data_en <= 1'b1;
                        mem_state              <= MEM_WRITE;
                    end
                end
                MEM_WRITE:
                begin
                    mem_cmd_en <= 1'b0;
                    if (mem_wr_fifo_empty)
                    begin
//                        mem_wr_fifo_rd_data_en <= 1'b0;
                        mem_state              <= MEM_WRITE_COMP;
                    end
                end
                MEM_WRITE_COMP:
                begin
                    mem_wr_req_ack <= 1'b1;
                    mem_state      <= MEM_IDLE;
                end
            endcase
        end
    end
    
    always_comb
    begin
        unique case (mem_state)
            MEM_IDLE:
            begin
                mem_wr_data            = 128'bz;
                mem_wr_data_en         = 1'b0;
                mem_wr_data_end        = 1'b0;
                mem_wr_fifo_rd_data_en = 1'b0;
                mem_rd_fifo_wr_data    = 128'bz;
                mem_rd_fifo_wr_data_en = 1'b0;
            end
            MEM_READ_REQ:
            begin
                mem_wr_data            = 128'bz;
                mem_wr_data_en         = 1'b0;
                mem_wr_data_end        = 1'b0;
                mem_wr_fifo_rd_data_en = 1'b0;
                mem_rd_fifo_wr_data    = 128'bz;
                mem_rd_fifo_wr_data_en = 1'b0;
            end
            MEM_READ:
            begin
                mem_wr_data            = 128'bz;
                mem_wr_data_en         = 1'b0;
                mem_wr_data_end        = 1'b0;
                mem_wr_fifo_rd_data_en = 1'b0;
                
                mem_rd_fifo_wr_data    = mem_rd_data_val ? mem_rd_data : 128'bz;
                mem_rd_fifo_wr_data_en = mem_rd_data_val;
            end
            MEM_READ_COMP:
            begin
                mem_wr_data            = 128'bz;
                mem_wr_data_en         = 1'b0;
                mem_wr_data_end        = 1'b0;
                mem_wr_fifo_rd_data_en = 1'b0;

                mem_rd_fifo_wr_data    = 128'bz;
                mem_rd_fifo_wr_data_en = 1'b0;
            end
            MEM_WRITE_REQ:
            begin
                mem_wr_fifo_rd_data_en = 1'b1;
                mem_wr_data            = mem_wr_fifo_rd_data_en ? mem_wr_fifo_rd_data : 128'bz;
                mem_wr_data_en         = mem_wr_fifo_rd_data_en;
                mem_wr_data_end        = mem_wr_fifo_rd_data_en;
                mem_rd_fifo_wr_data    = 128'bz;
                mem_rd_fifo_wr_data_en = 1'b0;
            end
            MEM_WRITE:
            begin
                mem_wr_fifo_rd_data_en = 1'b1;
                mem_wr_data            = mem_wr_fifo_rd_data_en ? mem_wr_fifo_rd_data : 128'bz;
                mem_wr_data_en         = !mem_wr_fifo_empty;
                mem_wr_data_end        = !mem_wr_fifo_empty;
//                mem_wr_fifo_rd_data_en = 0;
                mem_rd_fifo_wr_data    = 128'bz;
                mem_rd_fifo_wr_data_en = 1'b0;
            end
            MEM_WRITE_COMP:
            begin
                
                mem_wr_data            = 128'bz;
                mem_wr_data_en         = 1'b0;
                mem_wr_data_end        = 1'b0;
                mem_wr_fifo_rd_data_en = 1'b0;

                mem_rd_fifo_wr_data    = 128'bz;
                mem_rd_fifo_wr_data_en = 1'b0;
            end
            default:
            begin
                mem_wr_data            = 128'bz;
                mem_wr_data_en         = 1'b0;
                mem_wr_data_end        = 1'b0;
                mem_wr_fifo_rd_data_en = 1'b0;

                mem_rd_fifo_wr_data    = 128'bz;
                mem_rd_fifo_wr_data_en = 1'b0;
            end
        endcase
    end

endmodule