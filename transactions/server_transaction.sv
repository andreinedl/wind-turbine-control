class server_transaction;
	
	// Variabila aleatoare pe 32 biti pentru datele care vor fi trimise catre server
	rand bit [31:0] data;				
	
	// Functie executata automat dupa apelul .randomize() pentru a afisa datele generate
	function void post_randomize();
		$display("--------- [Server Trans] post_randomize ------");
		$display("Write data: %b", data);
		$display("----------------------------------------------");
	endfunction
	
	// Functie pentru crearea unei copii independente a tranzactiei curente
	function server_transaction do_copy();
		server_transaction server_trans = new();
		server_trans.data = this.data;

		return server_trans;		
	endfunction
endclass