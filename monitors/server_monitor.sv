`define SV_INF_MON svr_vif.monitor_cb

class server_monitor;
	
	virtual	server_interface svr_vif;
	
	mailbox mon2scb;
	
	function new(virtual server_interface svr_vif, mailbox mon2scb);
		this.svr_vif = svr_vif;
		this.mon2scb = mon2scb;
	endfunction
	
	task main;
		forever begin
		
			server_transaction trans;
			@(posedge svr_vif.clk_i);
			
			if(`SV_INF_MON.pready) begin					//se asteapta o tranzactie (pready == 1)
				trans 		= new();						//cand se detecteaza o tranzactie, se creeaza obiectul de tip server_transaction
				trans.data 	= `SV_INF_MON.pwdata;			//si se copiaza in atributul "data" datele din semnalul "pwdata" de pe interfata
				mon2scb.put(trans);
				$display("%0t s-au transmis date pe mailbox-ul server-ului catre scoreboard", $time);
			end
			
		end
	endtask
endclass