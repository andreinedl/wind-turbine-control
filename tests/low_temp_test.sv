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
	// Instantierea mediului de testare si conectarea interfetelor virtuale la acesta
	env = new(input_intf, output_intf, server_intf);
	env.gen.repeat_count = 0;
	
	// Temperatura in parametri normali (15 grade). Incalzirea trebuie sa ramana oprita.
	env.gen.generate_single_transaction(			//T=40 => 15C
		.temp_value(40)
	);
	
	// Temperatura scade la pragul critic inferior de activare (5 grade). 
	// Incalzirea trebuie sa porneasca (heat_o = 1).
	env.gen.generate_single_transaction(			//T=40 => 5C
		.temp_value(30)
	);
	
	// Temperatura scade sub prag (la -5 grade). Incalzirea trebuie sa ramana activa.
	env.gen.generate_single_transaction(			//T=40 => -5C
		.temp_value(20)
	);
	
	// Temperatura creste pana la pragul de dezactivare (10 grade). 
	// se verifica histerezisul.
	env.gen.generate_single_transaction(			//T=40 => 10C
		.temp_value(35)
	);
	
	env.run();
end
endprogram