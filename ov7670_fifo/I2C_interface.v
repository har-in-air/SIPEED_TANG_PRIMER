// Engineer: <mfield@concepts.co.nz
// 
// Description: Send the commands to the OV7670 over an I2C-like interface
// Translated to Verilog : HN

module I2C_interface ( 
    input   wire i_clk,
    output  reg  o_wr_done,      // finished write transaction
    input   wire i_wr_en,     // write enable 
    output  reg  o_sclk = 1'b1,              
    inout   wire io_sda,  
    input   wire [7:0] i_slave_id,  // 8'h42 for OV7670           
    input   wire [7:0] i_reg_addr, 
    input   wire [7:0] i_reg_data
    );
                            
reg [7:0] divider = 8'd1; // 254 cycle pause before initial frame is sent
reg [31:0] busy_sr = 32'h0000_0000;
reg [31:0] data_sr = 32'hFFFF_FFFF;
reg sda = 1'bZ;
  
assign io_sda = sda;
    
always @ (busy_sr or data_sr[31]) 
begin
    // when the bus is idle between phases, sda is tri-stated
    if (busy_sr[11:10] == 2'b10 || busy_sr[20:19] == 2'b10 || busy_sr[29:28] == 2'b10) 
        sda <= 1'bZ;
    else // else sda is driven by data shift register
        sda <= data_sr[31];
end
        
always @ (posedge i_clk) 
begin
    o_wr_done <= 1'b0;
    // If all 31 bits are transmitted 
    if (busy_sr[31] == 0) 
        begin
        // Assert sclk high for starting new transmission
        o_sclk <= 1'b1;
        o_wr_done <= 1'b1;
        //  a new write transaction
        if (i_wr_en) 
            begin
            if (divider == 8'd0) 
                begin
                // Create a 32 bit shift register to send on SDA line
                // using 3-phase write transmission cycle
                // Data:  
                // 3'b100 -> SDA will go from 1 to 0 (while SCLK = 1) 
                //			to indicate a start transmission
                //           add don't care bit to separate phases
                // slave_id -> for OV7670 this is 8'h42). 
                //			The last bit of the slave_id is 0 => write
                // 1'b0   -> add don't care bit to separate phases
                // i_reg_addr -> 8bit register address
                // 1'b0   -> add don't care bit to separate phases
                // i_reg_data  -> 8bit register data
                // 1'b0  -> add don't care bit to separate phases
                // 2'b01 -> SDA will go from 0 to 1 (while SCLK = 1) 
                //			to indicate a stop tranmission                
                data_sr <= {3'b100, i_slave_id, 1'b0, i_reg_addr, 1'b0, i_reg_data, 1'b0, 2'b01};
                busy_sr <= {3'b111, 9'b111111111, 9'b111111111, 9'b111111111, 2'b11};
                //o_wr_done <= 1'b1;
                end
            else 
                begin
                divider <= divider + 8'd1; // this only happens on power up
                end
            end
        end
    
    // Implement two-write data transmission of SCCB protocol
    else 
        begin
        case ({busy_sr[31:29],busy_sr[2:0]}) // Checking for the start and stop condition
            6'b111_111: // start seq #1
                begin                // data_sr[31] is transmitted, sclk must be high
                case (divider[7:6])          // -> sda goes from tri-state to high             
                    2'b00: o_sclk <= 1;          
                    2'b01: o_sclk <= 1;          
                    2'b10: o_sclk <= 1;          
                    default: o_sclk <= 1;
                endcase
                end
            
            6'b111_110:  // start seq #2
                begin                // data_sr[30] is transmitted
                case (divider[7:6])       // Sda goes from high to low, while sclk is high
                    2'b00: o_sclk <= 1;   // complete START condition
                    2'b01: o_sclk <= 1;
                    2'b10: o_sclk <= 1;
                    default: o_sclk <= 1;
                endcase
                end
        
            6'b111_100: // start seq #3
                begin             // data_sr[29] is transmitted (don't care bit)
                case (divider[7:6])  //sda goes from tri-state to high, then high to low 
                    2'b00: o_sclk <= 0;// after sclk goes from high to low 
                    2'b01: o_sclk <= 0;// Ready for first transmission from Master to Slave
                    2'b10: o_sclk <= 0;
                    default: o_sclk <= 0;
                endcase
                end
        
            6'b110_000: // stop seq #1
                begin             // data_sr[2] is transmitted (don't care bit)
                case (divider[7:6])  // sclk waits for 1 clock cyle, then goes high    
                    2'b00: o_sclk <= 0;
                    2'b01: o_sclk <= 1;
                    2'b10: o_sclk <= 1;
                    default: o_sclk <= 1;
                endcase
                end
        
            6'b100_000: // end seq #2
                begin              // data_sr[1] is transmitted
                case (divider[7:6])   // Sda is low
                    2'b00: o_sclk <= 1; // Sclk must be high
                    2'b01: o_sclk <= 1;
                    2'b10: o_sclk <= 1;
                    default: o_sclk <= 1;
                endcase
                end
        
            6'b000_000:  // idle 
                begin            
                case (divider[7:6])       
                    2'b00: o_sclk <= 1; 
                    2'b01: o_sclk <= 1; 
                    2'b10: o_sclk <= 1;
                    default: o_sclk <= 1;
                endcase
                end
            
           default: 
                begin                          
                case (divider[7:6])
                    2'b00: o_sclk <= 0;          
                    2'b01: o_sclk <= 1;          
                    2'b10: o_sclk <= 1;
                    default: o_sclk <= 0;
                endcase
                end
        endcase
    
    // Create a ~100kHz clock for SCCB  (24MHz / 256 = 93.75kHz )
    if (divider == 8'd255) 
        begin
        busy_sr <= {busy_sr[30:0], 1'b0};  // left shift busy_sr register
        data_sr <= {data_sr[30:0], 1'b1};  // left shift data_sr register
        divider <= 8'd0;                   // Reset counter for clock divider
        end
    else 
        begin
        divider <= divider + 8'd1;
        end
    end
end


endmodule

