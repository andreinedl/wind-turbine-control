// Acest test are rolul de a verifica functionalitatea dut-ului
// in cazul in care acesta primeste valori "ilegale" de la senzori.
// De exemplu, wind_dir_i este pe 10 biti, dar dut-ul accepta valori
// intre 0-720, deci range-ul 720-1023 este "zona interzisa".

program limit_test (
	input_interface 	input_intf,
	output_interface 	output_intf,
	server_interface 	server_intf
);


// mostenim clasa input_transaction
class illegal_values_trans extends input_transaction;
	
	// suprascriem functia pre_randomize
	// folosind .constraint_mode(0), dezactivam constrangerile originale
	function void pre_randomize();		//randomizarea este implicit activata
		this.wind_dir_c		.constraint_mode(0); 
		this.wind_speed_c	.constraint_mode(0);
		this.temp_c			.constraint_mode(0);
		this.rpm_c			.constraint_mode(0);
		this.blade_angle_c	.constraint_mode(0);
		this.yaw_angle_c	.constraint_mode(0);
	endfunction
	
	// Definim noi constrangeri pentru a forta valorile senzorilor in afara limitelor acceptate de DUT.
	// Acest lucru asigura ca DUT-ul limiteaza comanda sau nu are un comportament impredictibil.
	constraint wind_dir_limit_c {
		wind_dir_i > 720;				// Zona interzisa: 720-1023
	}

	constraint wind_speed_limit_c {
		wind_speed_i > 600;				// Zona interzisa: 600-1023
	}

	constraint temp_limit_c {
		temp_value_i > 100;				// Zona interzisa: 100-127
	}

	constraint rpm_limit_c {
		rpm_value_i > 350;				// Zona interzisa: 350-511
	}

	constraint blade_angle_limit_c {
		blade_angle_i > 180;			// Zona interzisa: 180-255
	}

	constraint yaw_angle_limit_c {
		yaw_angle_i > 720;				// Zona interzisa: 720-1023
	}
	
endclass

environment env;
illegal_values_trans illegal_trans;

initial begin
	$display("==== TEST VALORI INTERZISE ====");
	// Instantierea mediului de testare si conectarea interfetelor virtuale la acesta
	env = new(input_intf, output_intf, server_intf);
	illegal_trans = new();
	
	// Inlocuim tranzactia generatorului cu tranzactia mostenita
	env.gen.trans = illegal_trans;
	env.gen.repeat_count = 50;
	
	env.run();
end
endprogram
  