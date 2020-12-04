// Debounces active low push button and generates a 1-clock pulse output
// on button press.
// Does not generate any more pulses until the button is released 
// and pressed again

module debounce(
    input wire i_clk,
    input wire i_btn_n,
    output reg o_btn_1pulse = 1'b0
    );
    
    
reg [24:0] shift_reg = 25'b0;
wire bouncing;
wire low;

// detect button press
assign bouncing = |shift_reg[24:20]; // if true, was bouncing in this period
assign low = ~|shift_reg[19:0]; // if true, stopped bouncing, low for 0xFFFFF/24MHz = 43mS


always @(posedge i_clk)
begin
    shift_reg <= {shift_reg[23:0], i_btn_n};
    if (bouncing && low) 
        begin
        o_btn_1pulse <= 1'b1;
        shift_reg <= 25'b0;
        end
   else
        o_btn_1pulse <= 1'b0;
end

endmodule

