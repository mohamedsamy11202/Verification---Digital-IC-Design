	interface axi4_if #(
		parameter DATA_WIDTH = 32,
		parameter ADDR_WIDTH = 16,
		parameter MEMORY_DEPTH = 1024
	)(input bit ACLK);
	
	
	logic                     ARESETn;

	logic [ADDR_WIDTH-1:0]    AWADDR, ARADDR;
	logic [7:0]               AWLEN, ARLEN;
	logic [2:0]               AWSIZE, ARSIZE;
	logic                     AWVALID, AWREADY;

	logic [DATA_WIDTH-1:0]    WDATA, RDATA;
	logic                     WVALID, WREADY, WLAST;

	logic [1:0]               BRESP, RRESP;
	logic                     BVALID, BREADY ;
	logic                     ARVALID, ARREADY;
	logic                     RVALID, RLAST, RREADY;

	
	
	clocking cb @(posedge ACLK);
		default input #1step output negedge;
			output AWADDR,AWLEN,AWSIZE,AWVALID,WDATA,WVALID,WLAST,BREADY,ARADDR,ARLEN,ARSIZE,RREADY,ARVALID;
			input  AWREADY,WREADY,BRESP,BVALID,ARREADY,RDATA,RRESP,RLAST,RVALID ;
	endclocking


	modport TEST(clocking cb ,input ACLK, output ARESETn);
	
	modport DUT(input ACLK,ARESETn,AWADDR,AWLEN,AWSIZE,AWVALID,WDATA,WVALID,WLAST,BREADY,ARADDR,ARLEN,ARSIZE,RREADY,ARVALID,
				output AWREADY,WREADY,BRESP,BVALID,ARREADY,RDATA,RRESP,RLAST,RVALID);
	
	
	
	modport ASSERT(input ACLK,ARESETn,AWADDR,AWLEN,AWSIZE,AWVALID,WDATA,WVALID,WLAST,BREADY,ARADDR,ARLEN,ARSIZE,RREADY,ARVALID,
				   AWREADY,WREADY,BRESP,BVALID,ARREADY,RDATA,RRESP,RLAST,RVALID);
	
	endinterface
