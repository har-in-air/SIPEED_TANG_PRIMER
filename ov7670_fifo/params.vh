`ifndef PARAMS_H_
`define PARAMS_H_

`define n_BIT_CLKS_9600    2500 // 24MHz / 9600baud
`define n_BIT_CLKS_230400  104  // 24MHz / 230400baud
`define n_BIT_CLKS_460800  52  // 24MHz / 460800baud

`define n_BIT_CLKS `n_BIT_CLKS_460800

`define n_IMAGE_ROWS	    		240
`define n_IMAGE_ROW_BYTES	(320*2)
`define n_IMAGE_BYTES	    153600 // (rows * cols *2)




`endif
