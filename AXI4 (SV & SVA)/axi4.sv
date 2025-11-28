module axi4 #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 16,
    parameter MEMORY_DEPTH = 1024
)(axi4_if.DUT axi4if);

    // Internal memory signals
    // pragma coverage off
	reg mem_en, mem_we;
    reg [$clog2(MEMORY_DEPTH)-1:0] mem_addr;
    reg [DATA_WIDTH-1:0] mem_wdata;
    wire [DATA_WIDTH-1:0] mem_rdata;

    // Address and burst management
    reg [ADDR_WIDTH-1:0] write_addr, read_addr;
    reg [7:0] write_burst_len, read_burst_len;
    reg [7:0] write_burst_cnt, read_burst_cnt;
    
	
	reg [2:0] write_size, read_size;
    
	
    wire [ADDR_WIDTH-1:0] write_addr_incr, read_addr_incr;
    
    // Address increment calculation
    assign  write_addr_incr = (1 << write_size);
    assign  read_addr_incr  = (1 << read_size);
    
    // Address boundary check (4KB boundary = 12 bits)
	wire read_boundary_cross = ((read_addr & 16'hFFFF) + ((read_burst_len + 1) << read_size)) > 16'hFFFF;
	wire write_boundary_cross = ((write_addr & 16'hFFFF) + ((write_burst_len + 1) << write_size)) > 16'hFFFF;

    // Address range check
    wire write_addr_valid = (write_addr >> 2) < MEMORY_DEPTH;
    wire read_addr_valid  = (read_addr  >> 2) < MEMORY_DEPTH;
	
	// pragma coverage on

    // Memory instance
    axi4_memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH($clog2(MEMORY_DEPTH)),
        .DEPTH(MEMORY_DEPTH)
    ) mem_inst (
        .clk(axi4if.ACLK),
        .rst_n(axi4if.ARESETn),
        .mem_en(mem_en),
        .mem_we(mem_we),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata)
    );

	
    // FSM states
    reg [1:0] write_state;
    localparam W_IDLE = 2'd0,
               W_ADDR = 2'd1,
               W_DATA = 2'd2,
               W_RESP = 2'd3;

    reg [1:0] read_state;
    localparam R_IDLE = 2'd0,
               R_ADDR = 2'd1,
               R_DATA = 2'd2;


    always @(posedge axi4if.ACLK or negedge axi4if.ARESETn) begin
        if (!axi4if.ARESETn) begin
            // Reset all outputs
            axi4if.AWREADY <= 1'b1;  
            axi4if.WREADY  <= 1'b0;
            axi4if.BVALID  <= 1'b0;
            axi4if.BRESP   <= 2'b00;
            
            axi4if.ARREADY <= 1'b1;  
            axi4if.RVALID  <= 1'b0;
            axi4if.RRESP   <= 2'b00;
            axi4if.RDATA   <= {DATA_WIDTH{1'b0}};
            axi4if.RLAST   <= 1'b0;
            
            write_state <= W_IDLE;
            read_state  <= R_IDLE;
            mem_en      <= 1'b0;
            mem_we      <= 1'b0;
            mem_addr    <= {$clog2(MEMORY_DEPTH){1'b0}};
            mem_wdata   <= {DATA_WIDTH{1'b0}};
            
            write_addr       <= {ADDR_WIDTH{1'b0}};
            read_addr        <= {ADDR_WIDTH{1'b0}};
            write_burst_len  <= 8'b0;
            read_burst_len   <= 8'b0;
            write_burst_cnt  <= 8'b0;
            read_burst_cnt   <= 8'b0;
            write_size       <= 3'b0;
            read_size        <= 3'b0;

            
        end else begin
            mem_en <= 1'b0;
            mem_we <= 1'b0;

            // --------------------------
            // Write Channel FSM
            // --------------------------
            case (write_state)
                W_IDLE: begin
                    axi4if.AWREADY <= 1'b1;
                    axi4if.WREADY  <= 1'b0;
                    axi4if.BVALID  <= 1'b0;
                    // pragma coverage off
                    if (axi4if.AWVALID && axi4if.AWREADY) begin
					// pragma coverage on
                        write_addr       <= axi4if.AWADDR;
                        write_burst_len  <= axi4if.AWLEN;
                        write_burst_cnt  <= axi4if.AWLEN;
                        
						// pragma coverage off
						write_size       <= axi4if.AWSIZE;
                        // pragma coverage on
						
                        axi4if.AWREADY   <= 1'b0;
                        write_state      <= W_ADDR;
                    end
                end
                
                W_ADDR: begin
                    axi4if.WREADY  <= 1'b1;
                    
// pragma coverage off
					if (write_addr_valid && !write_boundary_cross) begin
// pragma coverage on
							write_state <= W_DATA;
							mem_en   <= 1'b1;
                            mem_we   <= 1'b1;
                            mem_addr <= write_addr >> 2;  
                            mem_wdata<= axi4if.WDATA;							
					end 
					else begin
							write_state <= W_IDLE;  
							axi4if.BRESP <= 2'b10; 							
					end
					
                end
                
                W_DATA: begin
					// pragma coverage off
                    if (axi4if.WVALID && axi4if.WREADY) begin
                       // pragma coverage on
                        
                        if (axi4if.WLAST || (write_burst_cnt-1) == 0) begin
                            axi4if.WREADY <= 1'b0;
                            write_state   <= W_RESP;                                                 
                            axi4if.BVALID <= 1'b1;
							
                        end else begin
                            write_addr      <= write_addr + write_addr_incr;
                            write_burst_cnt <= write_burst_cnt - 1'b1;
                        end
                    end
					else begin
						write_state <= W_IDLE;
						axi4if.BRESP <= 2'b10; 
					end
					
                end
                
                W_RESP: begin
				// pragma coverage off
                    if (axi4if.BREADY && axi4if.BVALID) begin
                     // pragma coverage on
					 axi4if.BVALID <= 1'b0;
                        axi4if.BRESP  <= 2'b00;
                        write_state   <= W_IDLE;
                    end
                end
                
				// pragma coverage off
                default: write_state <= W_IDLE;
				// pragma coverage on
				
            endcase

            // --------------------------
            // Read Channel FSM
            // --------------------------
            case (read_state)
                R_IDLE: begin
                    axi4if.ARREADY <= 1'b1;
                    axi4if.RVALID  <= 1'b0;
                    axi4if.RLAST   <= 1'b0;
                    // pragma coverage off
                    if (axi4if.ARVALID && axi4if.ARREADY) begin
                    // pragma coverage on   
					    read_addr       <= axi4if.ARADDR; 
                        read_burst_len  <= axi4if.ARLEN;
                        read_burst_cnt  <= axi4if.ARLEN;
                        
						// pragma coverage off
						read_size       <= axi4if.ARSIZE;
                        // pragma coverage on
						
                        axi4if.ARREADY  <= 1'b0;
                        read_state      <= R_ADDR;
                    end
                end
                
                R_ADDR: begin
               // pragma coverage off   
					if (read_addr_valid && !read_boundary_cross) begin
				// pragma coverage on	
					mem_en   <= 1'b1;
						mem_addr <= read_addr >> 2;
						read_state <= R_DATA;   
						axi4if.RRESP <= 2'b00;  
					end else begin
						read_state <= R_IDLE; 
						axi4if.RDATA <= {DATA_WIDTH{1'b0}};
                        axi4if.RRESP <= 2'b10; 						
					end
				

                end
                
                R_DATA: begin

                    axi4if.RDATA <= mem_rdata;                                           
                    axi4if.RVALID <= 1'b1;
                    axi4if.RLAST  <= (read_burst_cnt == 0);
                    // pragma coverage off
                    if (axi4if.RREADY && axi4if.RVALID) begin
                    // pragma coverage on    
						axi4if.RVALID <= 1'b0;
                        
                        if (read_burst_cnt > 0) begin
                            read_addr      <= read_addr + read_addr_incr;
                            read_burst_cnt <= read_burst_cnt - 1'b1;
                            
                           
                            mem_en   <= 1'b1;
                            mem_addr <= (read_addr + read_addr_incr) >> 2;
                            
                        end else begin
                            axi4if.RLAST  <= 1'b0;
                            read_state    <= R_IDLE;
                        end
                    end
                end
                
				// pragma coverage off
                default: read_state <= R_IDLE;
				// pragma coverage on
            endcase
        end
    end

endmodule
