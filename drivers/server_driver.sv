//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
//driverul preia datele de la generator, la nivel abstract, si le trimite DUT-ului conform protocolului de comunicatie pe interfata respectiva
//gets the packet from generator and drive the transaction packet items into interface (interface is connected to DUT, so the items driven into interface signal will get driven in to DUT) 

//se declara macro-ul SVR_DRIV_IF care va reprezenta interfata pe care driverul va trimite date DUT-ului
`define SVR_DRIV_IF svr_vif.driver_cb
class server_driver;
  
  //used to count the number of transactions
  int no_transactions;
  
  //creating virtual interface handle
  virtual svr_interface svr_vif;
  
  //se creaza portul prin care driverul primeste datele la nivel abstract de la DUT
  //creating mailbox handle
  mailbox gen2driv;
  
  //constructor
  function new(virtual svr_interface svr_vif,mailbox gen2driv);
    //cand se creaza driverul, interfata pe care acesta trimite datele este conectata la interfata reala a DUT-ului
    //getting the interface
    this.svr_vif = svr_vif;
    //getting the mailbox handles from  environment 
    this.gen2driv = gen2driv;
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
    server_transaction trans;
      
    //se asteapta ca modulul sa iasa din reset
    wait(svr_vif.rst_ni); // reset activ in 0
    
    //daca nu are date de la generator, driverul ramane cu executia la linia de mai jos, pana cand primeste respectivele date
     wait(`SVR_DRIV_IF.psel && !`SVR_DRIV_IF.penable);//astept primul tact al unei tranzactii APB
      $display("--------- [DRIVER-TRANSFER: %0d] ---------",no_transactions);
      @(posedge svr_vif.clk_i);
        `SVR_DRIV_IF.pready    = 1;
      @(posedge svr_vif.clk_i);
        `SVR_DRIV_IF.pready    = 0;
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
          //transmiterea datelor se face permanent, dar este conditionta de primirea datelor de la monitor.
          forever
            drive();
        end
      join_any
      disable fork;
       reset();
    end
  endtask
        
endclass