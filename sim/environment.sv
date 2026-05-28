
//--------TRANZACTII-------//
`include "../transactions/input_transaction.sv"
`include "../transactions/output_transaction.sv"
`include "../transactions/server_transaction.sv"

//----------DRIVERS-----------//
`include "../drivers/input_driver.sv"
`include "../drivers/server_driver.sv"

//---------GENERATOARE---------//
`include "../generators/input_generator.sv"

//---------MONITOARE-----------//
`include "../monitors/input_monitor.sv"
`include "../monitors/output_monitor.sv"
`include "../monitors/server_monitor.sv"


//--------COVERAGE-----------//
`include "../coverage/input_coverage.sv"
`include "../coverage/output_coverage.sv"

//--------SCOREBOARD---------//
`include "scoreboard.sv"

class environment;

	//Declararea generator-ului
	input_generator gen;
	
	//Declararea driver-ului
	input_driver	input_driver;
	server_driver   server_driver;
	
	//Declararea monitoarelor
	input_monitor	i_mon;
	output_monitor	o_mon;
	server_monitor	s_mon;
	
	//Declararea mailbox-urilor
	mailbox			i_mon2scb;
	mailbox			o_mon2scb;
	mailbox			s_mon2scb;
	mailbox			gen2driv;
	
	//Declararea scoreboard-ului
	scoreboard      scb;
	event 			gen_ended;
	
	//Interfete virtuale
	virtual input_interface input_vif;
	virtual output_interface output_vif;
	virtual server_interface svr_vif;

	//Constructor
	function new(virtual input_interface input_vif	,
				 virtual output_interface output_vif,
				 virtual server_interface svr_vif);
				 
		this.input_vif 	= input_vif;
		this.output_vif = output_vif;
		this.svr_vif 	= svr_vif;
		
		gen2driv 	= new();		//Crearea obiectului mailbox generator -> driver
		i_mon2scb 	= new();
		o_mon2scb	= new();
		s_mon2scb	= new();		//Crearea obiectelor mailbox de la - input_monitor	}
									//								   - output_monitor } -> scoreboard
									//								   - server_monitor	}
		
		//Instantierea generatorului si a driverelor
		gen = new(gen2driv, gen_ended);
		input_driver = new(input_vif, gen2driv);
		server_driver = new(svr_vif);
		
		//Instantierea monitoarelor
		i_mon = new(input_vif, i_mon2scb);
		o_mon = new(output_vif, o_mon2scb);
		s_mon = new(svr_vif, s_mon2scb);
		
		//Instantierea scoreboardului
		scb = new(i_mon2scb, o_mon2scb, s_mon2scb, input_vif);
	endfunction
	
	//Task care se ocupa cu resetarea driverelor inainte de test
	task pre_test();
		fork
			input_driver.reset();
			server_driver.reset();
		join
	endtask
	
	//Task care se ocupa cu apelarea functiei main() a elementelor mediului de verificare la rularea testului
	task test();
		fork
		gen.main();
		input_driver.main();
		server_driver.main();
		
		i_mon.main();
		o_mon.main();
		s_mon.main();

		scb.main();
		join_any
	endtask
	
	//Task care asteapta finalizarea testului
	task post_test();
		wait(gen_ended.triggered);
		wait(gen.repeat_count == input_driver.no_transactions);
		wait(gen.repeat_count == scb.no_transactions);
		#400;
	endtask
	
	//Functie care se ocupa cu afisarea rapoartelor de coverage
	function report();
		scb.input_cov.print_coverage();
		scb.output_cov.print_coverage();
	endfunction
	
	//Task care ruleaza fluxul principal de taskuri
	task run;
		pre_test();
		test();
		post_test();
		report();
		$finish;
	endtask
	
endclass