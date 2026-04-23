//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
//monitorul urmareste traficul de pe interfetele DUT-ului, preia datele verificate si recompune tranzactiile (folosind obiecte ale clasei transaction); in implementarea de fata, datele preluate de pe interfete sunt trimise scoreboardului pentru verificare
//Samples the interface signals, captures into transaction packet and send the packet to scoreboard.

//in macro-ul INPUT_MON_IF se retine blocul de semnale de unde monitorul extrage datele
`define INPUT_MON_IF input_vif.monitor_cb
class input_monitor;
  
  //creating virtual interface handle
  virtual input_interface input_vif;
  
  //se creaza portul prin care monitorul trimite scoreboardului datele colectate de pe interfata DUT-ului sub forma de tranzactii 
  //creating mailbox handle
  mailbox mon2scb;
  
  //cand se creaza obiectul de tip monitor (in fisierul environment.sv), interfata de pe care acesta colecteaza date este conectata la interfata reala a DUT-ului
  //constructor
  function new(virtual input_interface input_vif,mailbox mon2scb);
    //getting the interface
    this.input_vif = input_vif;
    //getting the mailbox handles from  environment 
    this.mon2scb = mon2scb;
  endfunction
  
  //Samples the interface signal and send the sample packet to scoreboard
  task main;
    forever begin
      //se declara si se creaza obiectul de tip tranzactie care va contine datele preluate de pe interfata
      input_transaction trans;
      trans = new();

      //datele sunt citite pe frontul de ceas, informatiile preluate de pe semnale fiind retinute in oboiectul de tip tranzactie
      @(posedge input_vif.clk_i);
     
        trans.wind_dir_i  = `INPUT_MON_IF.wind_dir_i;
        trans.wind_speed_i = `INPUT_MON_IF.wind_speed_i;
        trans.temp_value_i = `INPUT_MON_IF.temp_value_i;
        trans.rpm_value_i = `INPUT_MON_IF.rpm_value_i;
        trans.blade_angle_i = `INPUT_MON_IF.blade_angle_i;
        trans.yaw_angle_i = `INPUT_MON_IF.yaw_angle_i;
        //trans.error_feedback_i = `INPUT_MON_IF.error_feedback_i;
        
      // dupa ce s-au retinut informatiile referitoare la o tranzactie, continutul obiectului trans se trimite catre scoreboard
        mon2scb.put(trans);
    end
  endtask
  
endclass