`define SV_INF_MON svr_vif.monitor_cb

class server_monitor;
	
	virtual	server_interface svr_vif;   // Conexiunea la semnalele fizice
	mailbox mon2scb;                    // Canalul de comunicare catre Scoreboard
	
	function new(virtual server_interface svr_vif, mailbox mon2scb);
		this.svr_vif = svr_vif;
		this.mon2scb = mon2scb;
	endfunction
	
	task main;
		forever begin
			// Se asteapta frontul crescator al ceasului principal
			@(posedge svr_vif.clk_i);
			
			// Daca transferul este gata/valid pe interfata
			if(`SV_INF_MON.pready) begin
				// Se instantiaza o tranzactie noua
				server_transaction trans = new();
				// Se preiau datele de pe pinii fizici
				trans.data = `SV_INF_MON.pwdata;
				// Se trimite tranzactia spre analiza
				mon2scb.put(trans);
				$display("%0t S-au transmis date pe mailbox-ul server-ului catre scoreboard", $time);
			end
			
		end
	endtask
endclass