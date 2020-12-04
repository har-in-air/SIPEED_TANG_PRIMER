// https://www.nandland.com/vhdl/modules/module-uart-serial-port-rs232.html

`include "params.vh"

module uart_tx (
    input wire i_clk,
    input wire [7:0] i_tx_data,
    input wire i_tx_en,
    output reg o_txd,
    output reg o_tx_busy,
    output reg o_tx_done
);


localparam [2:0]
    st_idle  = 3'd0,
    st_start_bit = 3'd1,
    st_data_bits  = 3'd2,
    st_stop_bit  = 3'd3,
    st_cleanup = 3'd4;
    
reg [7:0]  tx_data = 8'd0;
reg [2:0]  tx_state = st_idle;
reg [11:0] clk_count = 12'd0;
reg [2:0]  bit_index = 3'd0;

always @(posedge i_clk)
    begin
        case (tx_state) 
            st_idle :
            begin
                o_txd <= 1'b1; // drive line high in idle state
                o_tx_busy <= 1'b0;
                o_tx_done <= 1'b0;
                clk_count <= 12'd0;
                bit_index <= 3'd0;
                if (i_tx_en)
                    begin
                    tx_data <= i_tx_data;
                    tx_state <= st_start_bit;
                    end
                else
                    begin
                    tx_state <= st_idle;
                    end
             end
             
             st_start_bit :
             begin
                o_tx_busy <= 1'b1;
                o_txd <= 1'b0;
                if (clk_count < `n_BIT_CLKS-1)
                    begin
                    clk_count <= clk_count + 12'd1;
                    tx_state <= st_start_bit;
                    end
                else
                    begin
                    clk_count <= 12'd0;
                    tx_state <= st_data_bits;
                    end             
             end 
            
            st_data_bits :
            begin
                o_txd <= tx_data[bit_index];
                if (clk_count < `n_BIT_CLKS-1)
                    begin
                    clk_count <= clk_count + 12'd1;
                    tx_state <= st_data_bits;
                    end
                else
                    begin
                    clk_count <= 12'd0;
                    if (bit_index < 7)
                        begin
                        bit_index <= bit_index + 3'd1;
                        tx_state <= st_data_bits;
                        end
                    else 
                        begin
                        bit_index <= 3'd0;
                        tx_state <= st_stop_bit;
                        end
                    end
            end
            
            st_stop_bit :
            begin
                o_txd <= 1'b1; // stop bit is 1
                if (clk_count < `n_BIT_CLKS-1)
                    begin
                    clk_count <= clk_count + 12'd1;
                    tx_state <= st_stop_bit;
                    end
                else
                    begin
                    o_tx_done <= 1'b1;
                    clk_count <= 12'd0;
                    tx_state <= st_cleanup;
                    end
            end
            
            
            st_cleanup :
            begin
                o_tx_busy <= 1'b0;
                o_tx_done <= 1'b0;
                tx_state <= st_idle;              
            end
            
            default :
                tx_state <= st_idle;
         endcase
    end
    
endmodule
         
