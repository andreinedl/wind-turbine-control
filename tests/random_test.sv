//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------

//tranzactiile din acest text se genereaza complet aleatoriu (singura constrangere fiind in fisierul transaction.sv, aceasta asigurand functionalitatea corecta a DUT-ului)
program random_test(
  input_interface  input_intf,
  output_interface output_intf,
  server_interface server_intf
);
  
  environment env;
  
  initial begin
    env = new(input_intf, output_intf, server_intf);
    
    // se genereaza 50 de tranzactii aleatorii
    env.gen.repeat_count = 50;
    
    env.run();
  end
endprogram