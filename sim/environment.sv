
//--------TRANZACTII-------//
`include "../transactions/input_transaction.sv"
`include "../transactions/output_transaction.sv"
`include "../transactions/server_transaction.sv"

//----------DRIVERS-----------//
`include "../drivers/input_driver.sv"

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


class environment;

	//Declararea generator-ului
	input_generator gen;
	
	//Declararea driver-ului
	input_driver	driver;
	
	//Declararea monitoarelor
	input_monitor	i_mon;
	output_monitor	o_mon;
	server_monitor	s_mon;

	//Declararea colectoarelor de coverage
	input_coverage	i_cov;
	output_coverage	o_cov;
	
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
		i_cov = new();
		o_cov = new();
		
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
		collect_input_coverage();
		collect_output_coverage();
		//scb.main();
		join_any
	endtask

	task collect_input_coverage();
		forever begin
			input_transaction in_tr;
			i_mon2scb.get(in_tr);
			i_cov.sample_function(in_tr);
		end
	endtask

	task collect_output_coverage();
		forever begin
			output_transaction out_tr;
			o_mon2scb.get(out_tr);
			o_cov.sample(out_tr);
		end
	endtask
	
	task post_test();
	//	wait(gen_ended.triggered);
	//	wait(gen.repeat_count == driver.no_transactions);
		//wait(gen.repeat_count == scb.no_transactions);
		#400;

		// Goleste eventualele tranzactii ramase in mailbox-uri inainte de raport.
		while (i_mon2scb.num() > 0) begin
			input_transaction in_tr;
			i_mon2scb.get(in_tr);
			i_cov.sample_function(in_tr);
		end

		while (o_mon2scb.num() > 0) begin
			output_transaction out_tr;
			o_mon2scb.get(out_tr);
			o_cov.sample(out_tr);
		end
	endtask
	
	function report();
		i_cov.print_coverage();
		o_cov.print_coverage();
	endfunction
	
	task run;
		pre_test();
		//$stop;
		test();
		post_test();
		report();
		$finish;
	endtask
	
endclass