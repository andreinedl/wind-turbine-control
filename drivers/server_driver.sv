//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
// Server driver APB pentru interfata `server_interface`.
// Rolul lui este sa se comporte ca un slave pentru modulul APB al dut-ului:
// - asteapta iesirea din reset;
// - detecteaza inceputul unei tranzactii APB cand `psel=1` si `penable=0`;
// - ridica `pready=1` pe urmatorul tact pentru a confirma accesul;
// - coboara `pready` inapoi la 0 dupa incheierea tranzactiei;
// - la reset, opreste thread-urile active si readuce semnalele slave la 0.

//se declara macro-ul SVR_DRIV_IF care va reprezenta interfata pe care driverul va trimite date DUT-ului
`define SVR_DRIV_IF svr_vif.driver_cb
class server_driver;
  
  //used to count the number of transactions
  int no_transactions;
  
  //creating virtual interface handle
  virtual server_interface svr_vif;
  
  //constructor
  function new(virtual server_interface svr_vif);
    //cand se creaza driverul, interfata pe care acesta trimite datele este conectata la interfata reala a DUT-ului
    //getting the interface
    this.svr_vif = svr_vif;
  endfunction
  
  //Reset task, Reset the Interface signals to default/initial values
  task reset;
    wait(!svr_vif.rst_ni);
    $display("--------- [SERVER DRIVER] Reset Started ---------");
    `SVR_DRIV_IF.pslverr <= 0;
    `SVR_DRIV_IF.pready <= 0;  
    
    wait(svr_vif.rst_ni);
    $display("--------- [SERVER DRIVER] Reset Ended ---------");
  endtask
  
  //drives the transaction items to interface signals
  task drive;
    //se asteapta ca modulul sa iasa din reset
    wait(svr_vif.rst_ni); // reset activ in 0
    
    //Driverul ramane in asteptare pana cand primeste o cerere de la master-ul APB (DUT-ul)
    //Faza de Setup APB: asteptam primul tact al unei tranzactii (psel = 1, penable = 0)
    wait(`SVR_DRIV_IF.psel && !`SVR_DRIV_IF.penable); 
      $display("--------- [SERVER DRIVER-TRANSFER: %0d] ---------",no_transactions);
      @(posedge svr_vif.clk_i);
        //Faza de Access APB: DUT-ul seteaza penable = 1, iar Slave-ul trebuie sa raspunda
        //Setam pready = 1 pentru a indica faptul ca datele au fost acceptate
        `SVR_DRIV_IF.pready    <= 1;
      @(posedge svr_vif.clk_i);
        //Incheierea tranzactiei: coboram pready inapoi in 0 pentru urmatoarele cicluri
        `SVR_DRIV_IF.pready    <= 0;
      $display("-----------------------------------------");
      no_transactions++;
  endtask
  
    
  //Cele doua fire de executie de mai jos ruleaza in paralel. Dupa ce primul dintre ele se termina al doilea este intrerupt automat. Daca se activeaza reset-ul, nu se mai transmit date. 
  task main;
    forever begin
      fork
        //Thread-1: Waiting for reset
        begin
          wait(!svr_vif.rst_ni); //Reset activ in 0
        end
        //Thread-2: Calling drive task
        begin
          //Asteapta si raspunde la cererile APB intr-o bucla continua
          forever
            drive();
        end
      join_any
      // join_any termina bucla atunci cand apare reset-ul sau cand unul dintre fire se opreste.
      // disable fork curata imediat orice threaduri ramase active, astfel incat un `drive()` blocat
      // in asteptare sa nu continue dupa reinitializarea protocolului.
      disable fork; 
      // Dupa ce am oprit toate thread-urile, aducem slave-ul in starea initiala.
       reset();
    end
  endtask
        
endclass