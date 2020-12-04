// https://www.nandland.com/vhdl/modules/module-uart-serial-port-rs232.html

`include "params.vh"

module uart_rx (
    input wire i_clk,
    input wire i_rxd,
    output reg o_rx_done,
    output reg [7:0] o_rx_data
);


localparam [2:0]
    st_idle  = 3'd0,
    st_start_bit = 3'd1,
    st_data_bits  = 3'd2,
    st_stop_bit  = 3'd3,
    st_cleanup = 3'd4;
    
reg [2:0]   rx_state = st_idle;
reg [11:0]  clk_count = 12'd0;
reg [2:0]   bit_index = 3'd0;

always @(posedge i_clk)
    begin
        case (rx_state) 
            st_idle :
                begin
                o_rx_done <= 1'b0;
                o_rx_data <= 8'd0;
                clk_count <= 12'd0;
                bit_index <= 3'd0;
                rx_state <= ~i_rxd  ? st_start_bit : st_idle;
                end
                
            st_start_bit :
                begin
                if (clk_count == (`n_BIT_CLKS-1)/2) 
                    begin
                    if (~i_rxd)
                        begin 
                        clk_count <= 1'b0; // reset at middle of start bit
                        rx_state <= st_data_bits;
                        end
                    else
                        begin
                        rx_state <= st_idle;
                        end
                    end
                else
                    begin
                    clk_count <= clk_count + 12'd1;
                    rx_state <= st_start_bit;
                    end
                end
                
            st_data_bits :
                begin
                if (clk_count < `n_BIT_CLKS-1)
                    begin
                    clk_count <= clk_count + 12'd1;
                    rx_state <= st_data_bits;
                    end
                else
                    begin
                    clk_count <= 12'd0;
                    o_rx_data[bit_index] <= i_rxd;
                    if (bit_index < 7)
                        begin
                        bit_index <= bit_index + 3'd1;
                        rx_state <= st_data_bits;
                        end
                     else
                        begin
                        bit_index <= 3'd0;
                        rx_state <= st_stop_bit;
                        end
                    end
                end
                
            st_stop_bit :
                begin
                if (clk_count < `n_BIT_CLKS-1)
                    begin
                    clk_count <= clk_count + 12'd1;
                    rx_state <= st_stop_bit;
                    end
                else
                    begin
                    o_rx_done <= 1'b1;
                    clk_count <= 12'd0;
                    rx_state <= st_cleanup;
                    end
                end
            
            st_cleanup :
                begin
                o_rx_done <= 1'b0;
                rx_state <= st_idle;
                end
                
            default :
                rx_state <= st_idle;
         endcase
    end
    
    
endmodule
