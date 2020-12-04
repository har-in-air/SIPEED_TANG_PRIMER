module top (
	input wire i_clk_24m, 
	input wire i_rstn, 
	input wire i_rxd, 
	output wire o_txd
	);

// uart wires
wire [7:0] rx_data;
wire [7:0] tx_data;
wire tx_busy;
wire rx_done;
wire tx_done;
wire tx_en;

// sdram wires
wire valid; 
wire ready; 
wire [31:0] addr;
wire [31:0] wdata; 
wire [3:0] wstrb; 
wire [31:0] rdata;

wire pll_rst;
wire extlock;
wire sdram_ctrl_clk;
wire sdram_phy_clk;

assign pll_rst = ~i_rstn;


xpll inst_xpll(
.refclk(i_clk_24m),
.reset(pll_rst),
.extlock(extlock),
.clk0_out(sdram_ctrl_clk),
.clk1_out(sdram_phy_clk)
);

sys_sdram inst_sys_sdram(
    .clk(sdram_ctrl_clk),
    .phy_clk(sdram_phy_clk),
    .rst_n(i_rstn),
    .i_valid(valid),
    .o_ready(ready),
    .i_addr(addr),
    .i_wdata(wdata),
    .i_wstrb(wstrb),
    .o_rdata(rdata)
);

//wire sync_ready;

//flag_cross_domain inst_sync_ready(
//    .i_clk_24mA(sdram_ctrl_clk),
//    .i_flagA(ready),   // this is a one-clock pulse from the clkA domain
//    .i_clk_24mB(i_clk_24m),
//    .o_flagB(sync_ready)  // from which we generate a one-clock pulse in clkB domain
//);


uart_rx inst_uart_rx (
    .i_clk(i_clk_24m), 
    .i_rxd(i_rxd), 
    .o_rx_done(rx_done), 
    .o_rx_data(rx_data)
  );

uart_tx inst_uart_tx (
    .i_clk(i_clk_24m), 
    .i_tx_data(tx_data), 
    .i_tx_en(tx_en), 
    .o_txd(o_txd), 
    .o_tx_busy(tx_busy),
    .o_tx_done(tx_done)
  );
  

tester inst_tester (
    .i_clk(i_clk_24m), 
    .i_rstn(i_rstn), 

	// uart interface
    .i_rx_done(rx_done), 
    .i_rx_data(rx_data), 
    .o_tx_data(tx_data), 
    .o_tx_en(tx_en), 
    .i_tx_busy(tx_busy), 

	// sdram interface
//    .i_sys_sdram_ready(sync_ready),
    .i_sys_sdram_ready(ready),
    .o_sys_addr(addr), 
    .i_sys_data_from_sdram(rdata), 
    .o_sys_data_to_sdram(wdata), 
    .o_sys_write_str(wstrb),
    .o_sys_data_valid(valid)
  );




endmodule
