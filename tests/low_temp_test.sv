// Acest test are rolul de a testa
// functionalitatea modulului care
// controleaza incalzirea de urgenta.

program low_temp_test (
	input_interface 	input_intf,
	output_interface	output_intf,
	server_interface	server_intf
);

environment env;

initial begin

	env = new(input_intf, output_intf, server_intf);
	env.gen.repeat_count = 0;
	
	env.gen.generate_single_transaction(			//T=40 => 15C
		.temp_value(40)
	);
	
	env.gen.generate_single_transaction(			//T=40 => 5C
		.temp_value(30)
	);
	
	env.gen.generate_single_transaction(			//T=40 => -5C
		.temp_value(20)
	);
	
	env.gen.generate_single_transaction(			//T=40 => 10C
		.temp_value(35)
	);
	
	env.run();
end
endprogram