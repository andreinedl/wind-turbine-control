//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------

//tranzactiile din acest test se genereaza complet aleatoriu (singura constrangere fiind in fisierul transaction.sv, aceasta asigurand functionalitatea corecta a DUT-ului)
program random_test(
  input_interface  input_intf,
  output_interface output_intf,
  server_interface server_intf
);
  
  environment env;
  
  initial begin
    // Initializam mediul de verificare si conectam interfetele virtuale catre acesta
    env = new(input_intf, output_intf, server_intf);
    
    // Setam numarul de tranzactii aleatorii pe care generatorul le va produce
    env.gen.repeat_count = 50;
    
    // Pornim fluxul de executie: pre_test (reset) -> test (generare si monitorizare) -> post_test -> report
    env.run();
  end
endprogram