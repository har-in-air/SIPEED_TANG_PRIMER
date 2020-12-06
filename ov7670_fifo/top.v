module top (
	input wire i_clk_24m, 
	input wire i_rstn,
	 
	// uart
	input wire i_rxd, 
	output wire o_txd,
	
	// status
	output wire o_ledr,
	output wire o_ledg,
	output wire o_ledb,
	
	// AL422B FIFO interface

	output wire o_fifo_wen,
	output wire o_fifo_rck,
	output wire o_fifo_rrstn,
	output wire o_fifo_rstn,
	input wire [7:0] i_fifo_data,
	
	// OV7670 interface
	input wire  i_csi_href,
	input wire  i_csi_vsync,
	output wire o_csi_soic,
	inout wire  io_csi_soid
	);

// uart wires
wire [7:0] rx_data;
wire [7:0] tx_data;
wire tx_busy;
wire rx_done;
wire tx_done;
wire tx_en;

wire cam_config_done;

wire fifo_capture_start;
wire fifo_read_start;
wire fifo_rd_byte_str;
wire fifo_busy;
wire fifo_rrst_done;
wire data_ready;
wire [7:0] image_data;

assign o_ledr = ~fifo_busy; // on when busy
assign o_ledg = ~cam_config_done; // on when camera config complete
assign o_ledb = 1'b1; // off

OV7670_config inst_OV7670_config(
    .i_clk(i_clk_24m),          
    .i_rstn(i_rstn),
    .o_config_done(cam_config_done),  
    .o_soic(o_csi_soic),       
    .io_soid(io_csi_soid),     
    .o_reset(o_fifo_rstn)
  );  

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
  
fifo_capture inst_fifo_capture (
    .i_clk(i_clk_24m),
    .i_rstn(i_rstn),

    .i_capture_start(fifo_capture_start),
    .i_read_start(fifo_read_start),  
    .i_rd_byte_str(fifo_rd_byte_str),
    .o_fifo_busy(fifo_busy),
    .o_fifo_rrst_done(fifo_rrst_done),
    .o_data(image_data),
    .o_data_rdy(data_ready),

	.i_vsync(i_csi_vsync),
    .i_fifo_data(i_fifo_data),
    .o_fifo_rck(o_fifo_rck),
    .o_fifo_wen(o_fifo_wen),
    .o_fifo_rrstn(o_fifo_rrstn)
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

    //camfifo interface
    .i_fifo_busy(fifo_busy),
    .o_capture_start(fifo_capture_start),
    .o_read_start(fifo_read_start),
    .i_fifo_rrst_done(fifo_rrst_done),
    .o_fifo_rd_byte_str(fifo_rd_byte_str),
    .i_data_ready(data_ready),
    .i_data_from_fifo(image_data)  
  );


endmodule
