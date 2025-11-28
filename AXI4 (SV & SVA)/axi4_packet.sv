class axi4_packet;

    localparam DATA_WIDTH   = 32;
    localparam ADDR_WIDTH   = 16;
    localparam MEMORY_DEPTH = 1024;
    localparam NUM_OF_Bytes_PER_BEAT  = 4; 

    bit    clk;
    rand logic  [ADDR_WIDTH-1:0] AWADDR_rand, ARADDR_rand;
    rand logic [7:0]             AWLEN_rand, ARLEN_rand;
    rand logic [DATA_WIDTH-1:0] WDATA_rand[];

    
    constraint len_c {
        AWLEN_rand inside {[0:20]};
        WDATA_rand.size() == (AWLEN_rand + 1);
    }

  
    constraint WADDR_C {
       
        (AWADDR_rand % NUM_OF_Bytes_PER_BEAT) == 0;
        AWADDR_rand >= 0;
        AWADDR_rand <= (MEMORY_DEPTH*NUM_OF_Bytes_PER_BEAT - (AWLEN_rand + 1) * NUM_OF_Bytes_PER_BEAT);        
       // ((AWADDR_rand & 'hFFFF) + ((AWLEN_rand + 1) * NUM_OF_Bytes_PER_BEAT)) <= 12'h1000;
    }

   
    constraint ARLEN_C {
        ARLEN_rand <= AWLEN_rand;
    }

   
    constraint RADDR_C {
        (ARADDR_rand % NUM_OF_Bytes_PER_BEAT) == 0;
        ARADDR_rand >= AWADDR_rand;
        ARADDR_rand <= AWADDR_rand + (AWLEN_rand * NUM_OF_Bytes_PER_BEAT);
    }

    constraint data_c {
        foreach (WDATA_rand[i]) {
            WDATA_rand[i] dist { '0 := 1, '1 := 1, [1:(2**DATA_WIDTH - 2)] := 8 };
        }
    }

    // covergroup
    covergroup cg;
        cp_addr : coverpoint AWADDR_rand { 
			bins low_addr = { [0:255] };
			bins mid_addr = { [256:2047] };
			bins high_addr = { [2048:(MEMORY_DEPTH*NUM_OF_Bytes_PER_BEAT - 1)] }; 
		} 
		
		cp_awlen : coverpoint AWLEN_rand { 
			bins len_short = { [0:3] }; 
			bins len_medium = { [4:10] }; 
			bins len_long = { [11:20] }; 
		} 
		
		cp_raddr : coverpoint ARADDR_rand {
			bins low_addr = { [0:255] }; 
			bins mid_addr = { [256:2047] }; 
			bins high_addr = { [2048:(MEMORY_DEPTH*NUM_OF_Bytes_PER_BEAT - 1)] };
		}
		
		cp_arlen : coverpoint ARLEN_rand { 
			bins len_short = { [0:3] }; 
			bins len_medium = { [4:10] }; 
			bins len_long = { [11:20] };
		}
	endgroup

    function new();
        cg = new();
    endfunction

endclass
