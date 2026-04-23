//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
//monitorul urmareste traficul de pe interfetele DUT-ului, preia datele verificate si recompune tranzactiile (folosind obiecte ale clasei transaction); in implementarea de fata, datele preluate de pe interfete sunt trimise scoreboardului pentru verificare
//Samples the interface signals, captures into transaction packet and send the packet to scoreboard.

//in macro-ul OUTPUT_MON_IF se retine blocul de semnale de unde monitorul extrage datele
`define OUTPUT_MON_IF output_vif.MONITOR.monitor_cb
class output_monitor;
  
  //creating virtual interface handle
  virtual output_interface output_vif;
  
  //se creaza portul prin care monitorul trimite scoreboardului datele colectate de pe interfata DUT-ului sub forma de tranzactii 
  //creating mailbox handle
  mailbox mon2scb;
  
  //cand se creaza obiectul de tip monitor (in fisierul environment.sv), interfata de pe care acesta colecteaza date este conectata la interfata reala a DUT-ului
  //constructor
  function new(virtual output_interface output_vif, mailbox mon2scb);
    //getting the interface
    this.output_vif = output_vif;
    //getting the mailbox handles from  environment 
    this.mon2scb = mon2scb;
  endfunction
  
  //Samples the interface signal and send the sample packet to scoreboard
  task main;
    forever begin
      //se declara si se creaza obiectul de tip tranzactie care va contine datele preluate de pe interfata
      output_transaction output_trans;
      output_trans = new();

      //datele sunt citite pe frontul de ceas, informatiile preluate de pe semnale fiind retinute in oboiectul de tip tranzactie
      @(posedge output_vif.MONITOR.clk_i);
      
        output_trans.blade_pos_o      = `OUTPUT_MON_IF.blade_pos_o;
        output_trans.yaw_pos_o        = `OUTPUT_MON_IF.yaw_pos_o;
        output_trans.heat_o           = `OUTPUT_MON_IF.heat_o;
        output_trans.em_brake_o       = `OUTPUT_MON_IF.em_brake_o;
        output_trans.error_feedback_o = `OUTPUT_MON_IF.error_feedback_o;

      // dupa ce s-au retinut informatiile referitoare la o tranzactie, continutul obiectului trans se trimite catre scoreboard
        mon2scb.put(output_trans);
    end
  endtask
  
endclass