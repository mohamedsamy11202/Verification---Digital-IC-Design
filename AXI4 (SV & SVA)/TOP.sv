`include "interface.sv"
`include "axi4.sv"
`include "Testbench.sv"

module TOP();
	parameter 	DATA_WIDTH   = 32;
	parameter	ADDR_WIDTH 	 = 16;
	parameter	MEMORY_DEPTH = 1024;
	
	bit ACLK = 0;
	always #10 ACLK = ~ACLK;
	
	
	axi4_if		#(DATA_WIDTH,ADDR_WIDTH,MEMORY_DEPTH)	axi4if(ACLK);
	axi4 		#(DATA_WIDTH,ADDR_WIDTH,MEMORY_DEPTH)	D1(axi4if.DUT);
	axi4_TB		#(DATA_WIDTH,ADDR_WIDTH,MEMORY_DEPTH)	T1(axi4if.TEST);
	assertion											A1(axi4if.ASSERT);
	

endmodule
