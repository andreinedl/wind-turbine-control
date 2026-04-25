//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------

//tranzactiile din acest text se genereaza complet aleatoriu (singura constrangere fiind in fisierul transaction.sv, aceasta asigurand functionalitatea corecta a DUT-ului)
program simple_test(
  input_interface input_intf,
  output_interface output_intf,
  server_interface server_intf
);
  
  //declaring environment instance
  environment env;
  
  initial begin
    //creating environment
    env = new(input_intf, output_intf, server_intf);
    
    //setting the repeat count of generator as 4, means to generate 4 packets
    env.gen.repeat_count = 0;
    
    // Vânt slab, direcția N
    env.gen.generate_single_transaction(
      .wind_speed(50), 
      .wind_dir(0)
    );

    // Vânt puternic, turație mare
    env.gen.generate_single_transaction(
      .wind_speed(300), 
      .rpm_value(250), 
      .temp_value(40)
    );

    // Temperatura mare (75 grade)
    env.gen.generate_single_transaction(
      .temp_value(100),
      .blade_angle(90)
    );
    
    //calling run of env, it interns calls generator and driver main tasks.
    env.run();
  end
endprogram