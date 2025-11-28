`timescale 1ns/1ps
`include "axi4_packet.sv"

module axi4_TB #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 16,	
	parameter MEMORY_DEPTH = 1024
) (axi4_if.TEST axi4if);

    //  Local Variables and Objects
    
    axi4_packet pkt;
	// Queues for write operation results 
	logic [1:0] Wactual_queue[$]; logic [1:0] Wexpected_queue[$];
	
	// Queues for read operation results 
	logic [1:0] Ractual_queue[$]; logic [1:0] Rexpected_queue[$];

    //  Initialization and Main Stimulus Flow
    int timeout;
	
	initial begin
        pkt = new();
        pkt.clk = axi4if.ACLK;

       
        axi4if.ARESETn = 0;

      
        axi4if.cb.AWADDR  <= 0;
        axi4if.cb.AWLEN   <= 0;
        axi4if.cb.AWSIZE  <= 2;
        axi4if.cb.AWVALID <= 0;

        axi4if.cb.WDATA   <= 0;
        axi4if.cb.WVALID  <= 0;
        axi4if.cb.WLAST   <= 0;

        axi4if.cb.BREADY  <= 0;

        axi4if.cb.ARADDR  <= 0;
        axi4if.cb.ARLEN   <= 0;
        axi4if.cb.ARSIZE  <= 2;
        axi4if.cb.ARVALID <= 0;

        axi4if.cb.RREADY  <= 0;

        #15;
        axi4if.ARESETn = 1;

     
		
        // WRITE Transactions
       
	   
        repeat (3000) begin
            generate_stimulus_w(pkt);
            drive_stim_W(pkt);
        end

       
        // READ Transactions
		
        repeat (3000) begin
            generate_stimulus_r(pkt);
            drive_stim_r(pkt);
        end

	$assertoff;

	@(posedge axi4if.ACLK);
		
		repeat(200)begin
			run_all_coverage_tests();
		end
		drive_stim_W_IDEL(pkt);
		
	$asserton;
	
        #50;
		axi4if.ARESETn = 0;
		#50;
        $display("AXI4 Testbench Completed Successfully");
        $stop;
    end


    
//////////  WRITE OPERATION TASKS //////////////
    

	task automatic generate_stimulus_w(ref axi4_packet pkt);
		assert(pkt.randomize()) else $fatal("Randomization failed for WRITE packet");
		  
	endtask


	task automatic drive_stim_W(ref axi4_packet pkt);
		@(posedge axi4if.ACLK);

		
		axi4if.cb.AWADDR  <= pkt.AWADDR_rand;
		axi4if.cb.AWLEN   <= pkt.AWLEN_rand;
		axi4if.cb.AWVALID <= 1;


		@(posedge axi4if.ACLK);
		wait (axi4if.cb.AWREADY == 1);


		if (axi4if.cb.AWREADY == 1) begin
			axi4if.cb.AWVALID <= 0;
			@(posedge axi4if.ACLK);
		end

		//$display("[%0t] WRITE ADDR: 0x%0h | AWLEN=%0d", $time, pkt.AWADDR_rand, pkt.AWLEN_rand);

		
		for (int beat = 0; beat <= pkt.AWLEN_rand; beat++) begin
			axi4if.cb.WDATA  <= pkt.WDATA_rand[beat];
			axi4if.cb.WVALID <= 1;
			axi4if.cb.WLAST  <= (beat == pkt.AWLEN_rand);
			
			pkt.cg.sample();
			
			//$display("[%0t] WDATA[%0d] = %0h | WLAST = %0b",$time, beat, pkt.WDATA_rand[beat], axi4if.cb.WLAST);

			@(posedge axi4if.ACLK);
		end

		
		axi4if.cb.BREADY <= 1;
		do @(posedge axi4if.ACLK);
		while (axi4if.cb.BVALID != 1);

		$display("[%0t] Write Response Received BRESP = %0h",$time, axi4if.cb.BRESP);
		collect_output_data_W(axi4if.cb.BRESP); 
		golden_model_W();
		check_results_W(); 
		
		@(posedge axi4if.ACLK);
		axi4if.cb.BREADY <= 0;
		
		
		
    endtask
	
	
	task automatic golden_model_W(); 
		Wexpected_queue.push_back('b00); 
	endtask 
		
	task automatic collect_output_data_W(input logic [1:0] Resp); 
		Wactual_queue.push_back(Resp); 
	endtask 
	
	task automatic check_results_W(); 
		for (int i = 0; i < Wexpected_queue.size(); i++) begin
			if (Wactual_queue[i] == Wexpected_queue[i]) 
				$display("[PASS] WRITE[%0d] Expected=%0b Got=%0b",i, Wexpected_queue[i], Wactual_queue[i]);
			else 
				$display("[FAIL] WRITE[%0d] Expected=%0b Got=%0b",i, Wexpected_queue[i], Wactual_queue[i]); 
		end 
		
		Wexpected_queue.delete(); 
		Wactual_queue.delete();
	endtask
	

    
//////////////  READ OPERATION TASKS ////////////////
  

	task automatic generate_stimulus_r(ref axi4_packet pkt);
        assert(pkt.randomize()) else $fatal("Randomization failed for READ packet");
		 pkt.cg.sample(); 
    endtask

    task automatic drive_stim_r(ref axi4_packet pkt);
        @(posedge axi4if.ACLK);

        axi4if.cb.ARADDR  <= pkt.ARADDR_rand;
        axi4if.cb.ARLEN   <= pkt.ARLEN_rand;
        axi4if.cb.ARVALID <= 1;

        
        do @(posedge axi4if.ACLK);
        while (axi4if.cb.ARREADY == 0);

        axi4if.cb.ARVALID <= 0;
        //$display("[%0t] READ ADDR: 0x%0h | ARLEN=%0d", $time, pkt.ARADDR_rand, pkt.ARLEN_rand);

        
        axi4if.cb.RREADY <= 1;
        
		do begin
		
	
		
		wait (axi4if.cb.RVALID == 1);
		
		@(posedge axi4if.ACLK);
			//$display("[%0t] READ DATA Received %0d ", $time, axi4if.cb.RDATA);
			pkt.cg.sample();
			
		end while (axi4if.cb.RLAST == 0);
		
		collect_output_data_R(); 
		golden_model_R(); 
		check_results_R();
		
        //$display("[%0t] READ COMPLETE  Last Data Beat Received", $time);
        axi4if.cb.RREADY <= 0;
		
    endtask

	
	task automatic golden_model_R(); 
		Rexpected_queue.push_back('b00);
	endtask 
	
	task automatic collect_output_data_R(); 
		Ractual_queue.push_back(axi4if.cb.RRESP); 
	endtask 
	
	task automatic check_results_R(); 
		for (int i = 0; i < Rexpected_queue.size(); i++) begin
		if (Ractual_queue[i] == Rexpected_queue[i]) 
			$display("[PASS] READ[%0d] Expected=%0b Got=%0b",i, Rexpected_queue[i], Ractual_queue[i]);
		else
			$display("[FAIL] READ[%0d] Expected=%0b Got=%0b", i, Rexpected_queue[i], Ractual_queue[i]);
		end 
		Ractual_queue.delete(); 
		Rexpected_queue.delete(); 
	endtask
	
		
	//////////  WRITE VIOLATION OPERATION TASKS //////////////

	task drive_stim_write_boundary_violation();
		$display("[%0t] >>> Starting WRITE boundary violation stimulus", $time);

	

		
		axi4if.cb.AWADDR  <= 16'hFFF0;
		axi4if.cb.AWLEN   <= 8'd20; 
		axi4if.cb.AWVALID <= 1;

		
		// Wait until AWREADY goes high
		@(posedge axi4if.ACLK);



		axi4if.cb.AWVALID <= 0;
		//$display("[%0t] WRITE ADDR: 0x%0h | AWLEN=%0d", $time, pkt.AWADDR_rand, pkt.AWLEN_rand);

		
		for (int beat = 0; beat <= axi4if.cb.AWLEN ; beat++) begin
			axi4if.cb.WDATA  <= $random;
			axi4if.cb.WVALID <= 1;
			axi4if.cb.WLAST  <= (beat == axi4if.cb.AWLEN );
			
			@(posedge axi4if.ACLK);
		end

		
		axi4if.cb.BREADY <= 1;
		@(posedge axi4if.ACLK);
		

		$display("[%0t] Write Response Received BRESP = %0h",$time, axi4if.cb.BRESP);

		@(posedge axi4if.ACLK);
		axi4if.cb.BREADY <= 0;

		$display("[%0t] <<< WRITE boundary violation complete", $time);
	endtask


	task drive_stim_invalid_write_addr();
		$display("[%0t] >>> Starting INVALID WRITE address stimulus", $time);

		@(posedge axi4if.ACLK);

		
		axi4if.cb.AWADDR  <= 16'h5000;
		axi4if.cb.AWLEN   <= 8'd4; 
		axi4if.cb.AWVALID <= 1;

		
		// Wait until AWREADY goes high
		@(posedge axi4if.ACLK);
		


		axi4if.cb.AWVALID <= 0;
		//$display("[%0t] WRITE ADDR: 0x%0h | AWLEN=%0d", $time, pkt.AWADDR_rand, pkt.AWLEN_rand);

		
		for (int beat = 0; beat <= axi4if.cb.AWLEN ; beat++) begin
			axi4if.cb.WDATA  <= $random;
			axi4if.cb.WVALID <= 1;
			axi4if.cb.WLAST  <= (beat == axi4if.cb.AWLEN );
			
			@(posedge axi4if.ACLK);
		end

		
		axi4if.cb.BREADY <= 1;


		$display("[%0t] Write Response Received BRESP = %0h",$time, axi4if.cb.BRESP);

		@(posedge axi4if.ACLK);
		axi4if.cb.BREADY <= 0;
		
		$display("[%0t] <<< INVALID WRITE address complete", $time);
	endtask


task drive_stim_wlast_missing();
    $display("[%0t] >>> Starting WLAST missing stimulus", $time);


		@(posedge axi4if.ACLK);

		
		axi4if.cb.AWADDR  <= 16'h0100;
		axi4if.cb.AWLEN   <= 8'd4; 
		axi4if.cb.AWVALID <= 1;

		
		// Wait until AWREADY goes high
		@(posedge axi4if.ACLK);
		wait (axi4if.cb.AWREADY == 1);


		axi4if.cb.AWVALID <= 0;
		//$display("[%0t] WRITE ADDR: 0x%0h | AWLEN=%0d", $time, pkt.AWADDR_rand, pkt.AWLEN_rand);

		
		for (int beat = 0; beat <= axi4if.cb.AWLEN ; beat++) begin
			axi4if.cb.WDATA  <= $random;
			axi4if.cb.WVALID <= 1;
			//axi4if.cb.WLAST  <= (beat == axi4if.cb.AWLEN );
			
			@(posedge axi4if.ACLK);
		end

		
		axi4if.cb.BREADY <= 1;
		do @(posedge axi4if.ACLK);
		while (axi4if.cb.BVALID != 1);

		$display("[%0t] Write Response Received BRESP = %0h",$time, axi4if.cb.BRESP);

		@(posedge axi4if.ACLK);
		axi4if.cb.BREADY <= 0;

    $display("[%0t] <<< WLAST missing stimulus complete", $time);
endtask





	task drive_stim_bready_hold_low();
		$display("[%0t] >>> Starting BREADY toggle stimulus", $time);

			@(posedge axi4if.ACLK);

		
		axi4if.cb.AWADDR  <= 16'h0100;
		axi4if.cb.AWLEN   <= 8'd4; 
		axi4if.cb.AWVALID <= 1;

		
		// Wait until AWREADY goes high
		@(posedge axi4if.ACLK);
		wait (axi4if.cb.AWREADY == 1);


		axi4if.cb.AWVALID <= 0;
		//$display("[%0t] WRITE ADDR: 0x%0h | AWLEN=%0d", $time, pkt.AWADDR_rand, pkt.AWLEN_rand);

		
		for (int beat = 0; beat <= axi4if.cb.AWLEN ; beat++) begin
			axi4if.cb.WDATA  <= $random;
			axi4if.cb.WVALID <= 1;
			axi4if.cb.WLAST  <= (beat == axi4if.cb.AWLEN );
			
			@(posedge axi4if.ACLK);
		end

		
		axi4if.cb.BREADY <= 1;
		do 	begin
		@(negedge axi4if.ACLK);
		axi4if.cb.BREADY <= ~axi4if.cb.BREADY;
		end while (axi4if.cb.BVALID != 1);

		$display("[%0t] Write Response Received BRESP = %0h",$time, axi4if.cb.BRESP);

		@(posedge axi4if.ACLK);
		axi4if.cb.BREADY <= 0;

		$display("[%0t] <<< BREADY toggle stimulus complete", $time);
	endtask





		task drive_stim_write_107();
		$display("[%0t] >>> Starting WRITE boundary violation stimulus", $time);

	
		@(posedge axi4if.ACLK);

		
		axi4if.cb.AWADDR  <= 16'h0FFF;
		axi4if.cb.AWLEN   <= 8'd20; 
		axi4if.cb.AWVALID <= 0;

		
		// Wait until AWREADY goes high
		@(posedge axi4if.ACLK);
		//wait (axi4if.cb.AWREADY == 1);


		axi4if.cb.AWVALID <= 0;
		//$display("[%0t] WRITE ADDR: 0x%0h | AWLEN=%0d", $time, pkt.AWADDR_rand, pkt.AWLEN_rand);

		
		for (int beat = 0; beat <= axi4if.cb.AWLEN ; beat++) begin
			axi4if.cb.WDATA  <= $random;
			axi4if.cb.WVALID <= 1;
			axi4if.cb.WLAST  <= (beat == axi4if.cb.AWLEN );
			
			@(posedge axi4if.ACLK);
		end

		
		axi4if.cb.BREADY <= 1;
		/*
		do @(posedge axi4if.ACLK);
		while (axi4if.cb.BVALID != 1);
*/
		$display("[%0t] Write Response Received BRESP = %0h",$time, axi4if.cb.BRESP);

		@(posedge axi4if.ACLK);
		axi4if.cb.BREADY <= 0;

		$display("[%0t] <<< WRITE boundary violation complete", $time);
	endtask











	//////////////  READ VIOLATION OPERATION TASKS ////////////////

	task drive_stim_read_boundary_violation();
		$display("[%0t] >>> Starting READ boundary violation stimulus", $time);

				 
			axi4if.cb.ARADDR  <= 16'hFFF0; 
			axi4if.cb.ARLEN   <=  8'd20;
			axi4if.cb.ARVALID <= 1;
     
         @(posedge axi4if.ACLK); 

        axi4if.cb.ARVALID <= 0;
        //$display("[%0t] READ ADDR: 0x%0h | ARLEN=%0d", $time, pkt.ARADDR_rand, pkt.ARLEN_rand);

        
        axi4if.cb.RREADY <= 1;
        


        //$display("[%0t] READ COMPLETE  Last Data Beat Received", $time);
        axi4if.cb.RREADY <= 0;

		$display("[%0t] <<< READ boundary violation complete", $time);
	endtask

	task drive_stim_invalid_read_addr();
		$display("[%0t] >>> Starting INVALID READ address stimulus", $time);

			axi4if.cb.ARADDR  <= 16'h5000; 
			axi4if.cb.ARLEN   <=  8'd8;
			axi4if.cb.ARVALID <= 1;

        
        @(posedge axi4if.ACLK);
    

        axi4if.cb.ARVALID <= 0;
        //$display("[%0t] READ ADDR: 0x%0h | ARLEN=%0d", $time, pkt.ARADDR_rand, pkt.ARLEN_rand);

        
        axi4if.cb.RREADY <= 1;
        

		

        //$display("[%0t] READ COMPLETE  Last Data Beat Received", $time);
        axi4if.cb.RREADY <= 0;
		
		$display("[%0t] <<< RREADY toggle stimulus complete", $time);
	endtask
	
	
	task drive_stim_rready_hold_low();
		$display("[%0t] >>> Starting BREADY toggle stimulus", $time);

			
			axi4if.cb.ARADDR  <= 16'h1500; 
			axi4if.cb.ARLEN   <=  8'd8;
			axi4if.cb.ARVALID <= 1;

        
        do @(posedge axi4if.ACLK);
        while (axi4if.cb.ARREADY == 0);

        axi4if.cb.ARVALID <= 0;
        //$display("[%0t] READ ADDR: 0x%0h | ARLEN=%0d", $time, pkt.ARADDR_rand, pkt.ARLEN_rand);

        
        axi4if.cb.RREADY <= 1;
        
		do begin
		@(negedge axi4if.ACLK);
		axi4if.cb.RREADY <= ~axi4if.cb.RREADY;
		wait (axi4if.cb.RVALID == 1);
		
		@(posedge axi4if.ACLK);
			//$display("[%0t] READ DATA Received %0d ", $time, axi4if.cb.RDATA);
			pkt.cg.sample();
			
		end while (axi4if.cb.RLAST == 0);
		

        //$display("[%0t] READ COMPLETE  Last Data Beat Received", $time);
        axi4if.cb.RREADY <= 0;

		$display("[%0t] <<< BREADY toggle stimulus complete", $time);
	endtask



	//////////////////////////////////////////////////////////////////////////////////////////////////////


	task run_all_coverage_tests();
		$display("[%0t] >>> RUNNING ENHANCED COVERAGE TESTS", $time);

		// 1) Normal directed violation tests you already wrote (boundary/invalid/etc)
		drive_stim_write_boundary_violation();
		drive_stim_read_boundary_violation();
		drive_stim_invalid_write_addr();
		drive_stim_invalid_read_addr();
		drive_stim_wlast_missing();
		


		$display("[%0t] <<< ENHANCED COVERAGE TESTS COMPLETE", $time);
	endtask




	task automatic drive_stim_W_IDEL(ref axi4_packet pkt);
		@(posedge axi4if.ACLK);

		
		axi4if.cb.AWADDR  <= 'h02f0;
		axi4if.cb.AWLEN   <= 'd12;
		axi4if.cb.AWVALID <= 1;
		
		axi4if.cb.WVALID <= 0;

		@(posedge axi4if.ACLK);
		wait (axi4if.cb.AWREADY == 1);

		// Drive AWVALID low for one cycle while AWREADY is still high
		if (axi4if.cb.AWREADY == 1) begin
			axi4if.cb.AWVALID <= 0;
			@(posedge axi4if.ACLK);
		end

		axi4if.cb.AWVALID <= 0;
		//$display("[%0t] WRITE ADDR: 0x%0h | AWLEN=%0d", $time, pkt.AWADDR_rand, pkt.AWLEN_rand);

		
		for (int beat = 0; beat <= pkt.AWLEN_rand; beat++) begin
			axi4if.cb.WDATA  <= pkt.WDATA_rand[beat];
			axi4if.cb.WVALID <= 0;
			axi4if.cb.WLAST  <= (beat == pkt.AWLEN_rand);
			
			
			
			//$display("[%0t] WDATA[%0d] = %0h | WLAST = %0b",$time, beat, pkt.WDATA_rand[beat], axi4if.cb.WLAST);

			@(posedge axi4if.ACLK);
		end


		
    endtask







endmodule

