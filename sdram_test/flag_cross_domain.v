// https://www.fpga4fun.com/CrossClockDomain2.html

module flag_cross_domain(
    input i_clkA,
    input i_flagA,   // this is a one-clock pulse from the clkA domain
    input i_clkB,
    output o_flagB  // from which we generate a one-clock pulse in clkB domain
);

reg flagToggle_clkA;

always @(posedge i_clkA) 
	flagToggle_clkA <= flagToggle_clkA ^ i_flagA;  // when flag is asserted, this signal toggles (clkA domain)

reg [2:0] syncA_clkB;

always @(posedge i_clkB) 
	syncA_clkB <= {syncA_clkB[1:0], flagToggle_clkA};  // now we cross the clock domains

assign o_flagB = (syncA_clkB[2] ^ syncA_clkB[1]);  // and create the clkB flag

endmodule
