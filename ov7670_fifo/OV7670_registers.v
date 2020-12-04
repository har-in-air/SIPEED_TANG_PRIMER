module OV7670_registers (
    input wire i_clk,
    input wire i_rstn,
    input wire i_config_start, // configuration start 1-clock pulse
    input wire i_next_reg,   // increment register index
    output reg [15:0] o_addr_data = 16'b0,
    output reg o_config_done = 1'b0
    );

reg [7:0] index = 8'd0;


// QVGA RGB565 configuration

always @(posedge i_clk) 
begin
    if ((~i_rstn) || i_config_start) 
        begin
        index <= 8'd0;
        o_config_done <= 1'b0;      
        o_addr_data <= 16'h0;  
        end
    else 
    if (i_next_reg && (~o_config_done)) 
        begin
        index <= index + 8'd1;
        end

    o_config_done <= (o_addr_data == 16'hFFFF);
    
    case (index) 
	8'd0 : o_addr_data <= 16'h12_80; // COM7 Reset
	8'd1 : o_addr_data <= 16'h12_80; // COM7 Reset
	8'd2 : o_addr_data <= 16'h11_80; 
	8'd3 : o_addr_data <= 16'h3B_0A; 
	8'd4 : o_addr_data <= 16'h3A_04; 
	8'd5 : o_addr_data <= 16'h12_04; // output format RGB
	8'd6 : o_addr_data <= 16'h8C_00; // disable RGB44 
	8'd7 : o_addr_data <= 16'h40_D0; // RGB565
	8'd8 : o_addr_data <= 16'h17_16; 
	8'd9 : o_addr_data <= 16'h18_04; 
	 
	8'd10 : o_addr_data <= 16'h32_24;
	8'd11 : o_addr_data <= 16'h19_02;
	8'd12 : o_addr_data <= 16'h1A_7A;
	8'd13 : o_addr_data <= 16'h03_0A;
	8'd14 : o_addr_data <= 16'h15_02; 
	8'd15 : o_addr_data <= 16'h0C_04; 
	8'd16 : o_addr_data <= 16'h1E_3F; 
	8'd17 : o_addr_data <= 16'h3E_19;
	8'd18 : o_addr_data <= 16'h72_11;
	8'd19 : o_addr_data <= 16'h73_F1;
	
	8'd20 : o_addr_data <= 16'h4F_80;
	8'd21 : o_addr_data <= 16'h50_80; 
	8'd22 : o_addr_data <= 16'h51_00; 
	8'd23 : o_addr_data <= 16'h52_22; 
	8'd24 : o_addr_data <= 16'h53_5E; 
	8'd25 : o_addr_data <= 16'h54_80; 
	8'd26 : o_addr_data <= 16'h56_40;
	8'd27 : o_addr_data <= 16'h58_9E;
	8'd28 : o_addr_data <= 16'h59_88;
	8'd29 : o_addr_data <= 16'h5A_88;
	
	8'd30 : o_addr_data <= 16'h5B_44;
	8'd31 : o_addr_data <= 16'h5C_67;
	8'd32 : o_addr_data <= 16'h5D_49;
	8'd33 : o_addr_data <= 16'h5E_0E;
	8'd34 : o_addr_data <= 16'h69_00;
	8'd35 : o_addr_data <= 16'h6A_40;
	8'd36 : o_addr_data <= 16'h6B_0A;
	8'd37 : o_addr_data <= 16'h6C_0A;
	8'd38 : o_addr_data <= 16'h6D_55;
	8'd39 : o_addr_data <= 16'h6E_11;
	
	8'd40 : o_addr_data <= 16'h6F_9F;
	8'd41 : o_addr_data <= 16'hB0_84; 
    default : o_addr_data <= 16'hFF_FF;    // End configuration
    endcase  
end

endmodule

