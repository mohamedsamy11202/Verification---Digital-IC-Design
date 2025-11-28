`timescale 1ns/1ps
`include "enum_pkg.sv"
`include "Uart_packet.sv"

module Uart_TB();

///////// Input /////////
	logic 			clk_TB			;
	logic 			rst_n_TB		;
	logic 			tx_start_TB		;
	logic 			parity_en_TB	;
	logic 			even_parity_TB	;
	logic [7:0] 	data_in_TB		;

///////// Output /////////
	logic tx_TB			;
	logic tx_busy_TB	;

///////// DUT /////////
	uart_tx DUT (
		.clk(clk_TB),
		.rst_n(rst_n_TB),
		.tx_start(tx_start_TB),
		.data_in(data_in_TB),
		.parity_en(parity_en_TB),   
		.even_parity(even_parity_TB),   
		
		.tx(tx_TB),
		.tx_busy(tx_busy_TB)
	);


	Uart_packet pkg;

///////// Clock gen /////////
	initial
		forever begin
			#5;		
			clk_TB   = ~clk_TB;
			pkg.clk =  clk_TB;
		
	end


///////// Initial /////////
	initial begin
		
		pkg = new();
		clk_TB		   = 0;
		rst_n_TB       = 0;
        tx_start_TB    = 0;
        parity_en_TB   = 0;
        even_parity_TB = 0;
        data_in_TB     = 8'h00;
		
		#15;
		rst_n_TB = 1;
		
		repeat(20) begin
			assert(pkg.randomize())else $fatal("Randomize faild");
			  $display("New packet: dyn_size=%0d parity=%0s", pkg.dyn.size(), pkg.parity_type.name());
			  pkg.drive_stim(clk_TB, tx_start_TB, parity_en_TB, even_parity_TB, data_in_TB, tx_TB, tx_busy_TB);			  
		end
		
		#100;
        pkg.check_results();

		$stop;
	end


endmodule
