module OV7670_registers (
    input wire i_clk,
    input wire [5:0] i_reg_index,
    output reg [15:0] o_addr_data
    );

// QVGA RGB565 configuration

always @(posedge i_clk) 
begin
    case (i_reg_index) 
	6'd0 : o_addr_data <= 16'h12_80; // COM7 Reset
	6'd1 : o_addr_data <= 16'h12_80; // COM7 Reset
	6'd2 : o_addr_data <= 16'h11_80; 
	6'd3 : o_addr_data <= 16'h3B_0A; 
	6'd4 : o_addr_data <= 16'h3A_04; 
	6'd5 : o_addr_data <= 16'h12_04; // output format RGB
	6'd6 : o_addr_data <= 16'h8C_00; // disable RGB44 
	6'd7 : o_addr_data <= 16'h40_D0; // RGB565
	6'd8 : o_addr_data <= 16'h17_16; 
	6'd9 : o_addr_data <= 16'h18_04; 
	 
	6'd10 : o_addr_data <= 16'h32_24;
	6'd11 : o_addr_data <= 16'h19_02;
	6'd12 : o_addr_data <= 16'h1A_7A;
	6'd13 : o_addr_data <= 16'h03_0A;
	6'd14 : o_addr_data <= 16'h15_02; 
	6'd15 : o_addr_data <= 16'h0C_04; 
	6'd16 : o_addr_data <= 16'h1E_3F; 
	6'd17 : o_addr_data <= 16'h3E_19;
	6'd18 : o_addr_data <= 16'h72_11;
	6'd19 : o_addr_data <= 16'h73_F1;
	
	6'd20 : o_addr_data <= 16'h4F_80;
	6'd21 : o_addr_data <= 16'h50_80; 
	6'd22 : o_addr_data <= 16'h51_00; 
	6'd23 : o_addr_data <= 16'h52_22; 
	6'd24 : o_addr_data <= 16'h53_5E; 
	6'd25 : o_addr_data <= 16'h54_80; 
	6'd26 : o_addr_data <= 16'h56_40;
	6'd27 : o_addr_data <= 16'h58_9E;
	6'd28 : o_addr_data <= 16'h59_88;
	6'd29 : o_addr_data <= 16'h5A_88;
	
	6'd30 : o_addr_data <= 16'h5B_44;
	6'd31 : o_addr_data <= 16'h5C_67;
	6'd32 : o_addr_data <= 16'h5D_49;
	6'd33 : o_addr_data <= 16'h5E_0E;
	6'd34 : o_addr_data <= 16'h69_00;
	6'd35 : o_addr_data <= 16'h6A_40;
	6'd36 : o_addr_data <= 16'h6B_0A;
	6'd37 : o_addr_data <= 16'h6C_0A;
	6'd38 : o_addr_data <= 16'h6D_55;
	6'd39 : o_addr_data <= 16'h6E_11;
	
	6'd40 : o_addr_data <= 16'h6F_9F;
	6'd41 : o_addr_data <= 16'hB0_84; 
    default : o_addr_data <= 16'hFF_FF;    // End configuration
    endcase  
end

endmodule

