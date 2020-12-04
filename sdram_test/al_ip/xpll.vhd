--------------------------------------------------------------
 --  Copyright (c) 2011-2021 Anlogic, Inc.
 --  All Right Reserved.
--------------------------------------------------------------
 -- Log	:	This file is generated by Anlogic IP Generator.
 -- File	:	/home/hari/fpga/anlogic/anlogic_eg4s_sdram_controller/al_ip/xpll.vhd
 -- Date	:	2020 11 04
 -- TD version	:	4.6.14314
--------------------------------------------------------------

-------------------------------------------------------------------------------
--	Input frequency:             24.000Mhz
--	Clock multiplication factor: 7
--	Clock division factor:       1
--	Clock information:
--		Clock name	| Frequency 	| Phase shift
--		C0        	| 168.000000MHZ	| 0  DEG     
--		C1        	| 168.000000MHZ	| 120DEG     
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.std_logic_arith.ALL;
LIBRARY eagle_macro;
USE eagle_macro.EAGLE_COMPONENTS.ALL;

ENTITY xpll IS
	PORT ( refclk	: IN	STD_LOGIC;
		reset	: IN	STD_LOGIC;
		extlock	: OUT	STD_LOGIC;
		clk0_out	: OUT	STD_LOGIC;
		clk1_out	: OUT	STD_LOGIC);
END xpll;

ARCHITECTURE rtl OF xpll IS
	SIGNAL clk0_buf	: STD_LOGIC;
	SIGNAL fbk_wire	: STD_LOGIC;
	SIGNAL clkc_wire	: STD_LOGIC_VECTOR (4 DOWNTO 0);
BEGIN
	bufg_feedback : EG_LOGIC_BUFG
		PORT MAP ( i => clk0_buf, o => fbk_wire );

	pll_inst : EG_PHY_PLL	GENERIC MAP ( DPHASE_SOURCE => "DISABLE",
		DYNCFG => "DISABLE",
		FIN => "24.000",
		FEEDBK_MODE => "NORMAL",
		FEEDBK_PATH => "CLKC0_EXT",
		STDBY_ENABLE => "DISABLE",
		PLLRST_ENA => "ENABLE",
		SYNC_ENABLE => "DISABLE",
		DERIVE_PLL_CLOCKS => "ENABLE",
		GEN_BASIC_CLOCK => "ENABLE",
		GMC_GAIN => 2,
		ICP_CURRENT => 9,
		KVCO => 2,
		LPF_CAPACITOR => 1,
		LPF_RESISTOR => 8,
		REFCLK_DIV => 1,
		FBCLK_DIV => 7,
		CLKC0_ENABLE => "ENABLE",
		CLKC0_DIV => 6,
		CLKC0_CPHASE => 5,
		CLKC0_FPHASE => 0,
		CLKC1_ENABLE => "ENABLE",
		CLKC1_DIV => 6,
		CLKC1_CPHASE => 1,
		CLKC1_FPHASE => 0)
		PORT MAP ( refclk => refclk,
			reset => reset,
			stdby => '0',
			extlock => extlock,
			psclk => '0',
			psdown => '0',
			psstep => '0',
			psclksel => "000",
			dclk => '0',
			dcs => '0',
			dwe => '0',
			di => "00000000",
			daddr => "000000",
			fbclk => fbk_wire,
			clkc => clkc_wire);

		clk1_out <= clkc_wire(1);
		clk0_buf <= clkc_wire(0);
		clk0_out <= fbk_wire;

END rtl;
