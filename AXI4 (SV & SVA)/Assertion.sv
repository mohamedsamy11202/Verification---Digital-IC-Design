module assertion(axi4_if.ASSERT axi4if);


    // WRITE RESPONSE ASSERTION
	 property write_response_ok;
		@(posedge axi4if.ACLK)
		disable iff (!axi4if.ARESETn)
			(axi4if.BVALID && axi4if.BREADY) |=> (axi4if.BRESP == 2'b00);
	endproperty

	A1 : assert property(write_response_ok)
		$display("[%0t] WRITE RESPONSE PASSED : BRESP = %0b", $time, axi4if.BRESP);
	C1 : cover property(write_response_ok);


	
    // READ RESPONSE ASSERTION
    property read_response_ok;
		@(posedge axi4if.ACLK)
		disable iff (!axi4if.ARESETn)
		(axi4if.RLAST && axi4if.RREADY) |=> (axi4if.RRESP == 2'b00);
	endproperty

	A2 : assert property(read_response_ok)
		$display("[%0t] READ RESPONSE PASSED : RRESP = %0b", $time, axi4if.RRESP);
	C2 : cover property(read_response_ok);

endmodule