class server_transaction;
	
	rand bit [31:0] data;
	
	function void post_randomize();
		$display("--------- [Server Trans] post_randomize ------");
		$display("Write data: %b", data);
		$display("----------------------------------------------");
	endfunction
	
	function server_transaction do_copy();
		server_transaction server_trans;
		server_trans = new();
		server_trans.data = this.data;

		return server_trans;		
	endfunction
	
	
endclass