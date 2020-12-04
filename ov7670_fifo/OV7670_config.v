// Engineer: Mike Field <hamster@snap.net.nz>
// 
// Description: Controller for the OV760 camera - configure registers 
//              using SCCB (i2c ) bus
// Translated to Verilog with some modifications : HN

module OV7670_config (
    input wire i_clk,            
    input wire i_rstn,                
    input wire i_config_start,                           
    output wire o_config_done,                 
    output wire o_soic,                          
    inout wire io_soid,                           
    output wire o_reset,                         
    output wire o_dbg_wr_done                           
    );

wire [15:0] reg_addr_data;

wire wr_done;
wire wr_en;

assign o_reset = i_rstn;

assign wr_en = ~o_config_done;
assign o_dbg_wr_done = wr_done;

I2C_interface inst_I2C_interface(
    .i_clk(i_clk),
    .o_wr_done(wr_done), // write transaction completed                
    .i_wr_en(wr_en),   // start new write transaction              
    .o_sclk(o_soic),
    .io_sda(io_soid),
    .i_slave_id(8'h42), // OV7670 slave id
    .i_reg_addr(reg_addr_data[15:8]),
    .i_reg_data(reg_addr_data[7:0])  
    );

// LUT for OV7670 register addresses and data values
OV7670_registers inst_OV7670_registers(
    .i_clk(i_clk),        
    .i_rstn(i_rstn),                
    .i_config_start(i_config_start), // 1-clock pulse to configure the registers
    .i_next_reg(wr_done), // get next register address and data           
    .o_addr_data(reg_addr_data),
    .o_config_done(o_config_done) // finished configuration of all registers
    );


endmodule
