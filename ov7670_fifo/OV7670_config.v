module OV7670_config (
    input wire i_clk,            
    input wire i_rstn,                
    output reg o_config_done,                 
    output wire o_soic,                          
    inout wire io_soid,                           
    output wire o_reset                         
    );

localparam [2:0]
	fsm_idle = 3'd0,
	fsm_wr = 3'd1,
	fsm_wr_ack = 3'd2,
	fsm_config_done = 3'd3;

reg [2:0] fsm_state = fsm_wr;	
reg [5:0] reg_index = 6'd0;
wire  wr_en;

wire [15:0] reg_addr_data;
wire wr_done;
	
assign o_reset = i_rstn;
assign wr_en = (fsm_state != fsm_config_done);

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
    .i_reg_index(reg_index),                
    .o_addr_data(reg_addr_data)
    );

always @(posedge i_clk)
begin
	if (~i_rstn)
		begin
		o_config_done <= 0;
		reg_index <= 6'd0;
	    fsm_state <= fsm_wr;
		end
	else
	begin
	case (fsm_state)
	fsm_wr :
		fsm_state <= (reg_index == 6'd42) ? fsm_config_done : fsm_wr_ack;
		
	fsm_wr_ack:
		begin
		if (wr_done)
		    begin
   			reg_index <= reg_index + 6'd1;
   			fsm_state <= fsm_wr;
    		end
		end

	fsm_config_done : o_config_done <= 1;

	default : ;
	
	endcase
	end
			
end    
endmodule
