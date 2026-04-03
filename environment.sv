
//--------TRANSACTII-------//
`include "input_transaction.sv"
`include "output_transaction.sv"
`include "server_transaction.sv"

//----------DRIVERS-----------//
`include "input_driver.sv"

//---------GENERATOARE---------//
`include "input_generator.sv"

//---------MONITOARE-----------//
`include "input_monitor.sv"
`include "output_monitor.sv"
`include "server_monitor.sv"


//--------COVERAGE-----------//

//--------SCOREBOARD---------//


class environment;

	//Declararea generator-ului
	input_generator gen;
	
	//Declararea driver-ului
	input_driver	driver;
	
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
	
	event gen_ended;
	
	//Interfete virtuale
	virtual input_interface input_vif;
	virtual output_interface output_vif;
	virtual server_interface svr_vif;

	//Constructor
	function new(virtual input_interface input_vif	,
				 virtual output_interface output_vif,
				 virtual server_interface svr_vif	);
				 
		this.input_vif 	= input_vif;
		this.output_vif = output_vif;
		this.svr_vif 	= svr_vif;
		
		gen2driv 	= new();
		i_mon2scb 	= new();
		o_mon2scb	= new();
		s_mon2scb	= new();
		
		gen = new(gen2driv, gen_ended);
		driver = new(input_vif, gen2driv);
		
		i_mon = new(input_vif, i_mon2scb);
		o_mon = new(output_vif, o_mon2scb);
		s_mon = new(svr_vif, s_mon2scb);
		
		//Scoreboard
		//....
	endfunction
	
	task pre_test();
		driver.reset();
	endtask
	
	task test();
		fork
		gen.main();
		driver.main();
		i_mon.main();
		o_mon.main();
		s_mon.main();
		//scb.main();
		join_any
	endtask
	
	task post_test();
	//	wait(gen_ended.triggered);
	//	wait(gen.repeat_count == driver.no_transactions);
		//wait(gen.repeat_count == scb.no_transactions);
		#400
	endtask
	
	/*function report();
		scb.colector_coverage.print_coverage();
	endfunction */
	
	task run;
		pre_test();
		$stop;
		test();
		post_test();
		report();
		$finish;
	endtask
	
endclass