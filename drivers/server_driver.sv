//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
//Acest driver actioneaza ca un APB Slave (Server reactiv).
//Monitorizeaza interfata si cand Master-ul (DUT) initiaza o tranzactie (psel=1), raspunde cu pready=1.

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
     wait(`SVR_DRIV_IF.psel && !`SVR_DRIV_IF.penable);//astept primul tact al unei tranzactii APB
      $display("--------- [SERVER DRIVER-TRANSFER: %0d] ---------",no_transactions);
      @(posedge svr_vif.clk_i);
        `SVR_DRIV_IF.pready    <= 1;
      @(posedge svr_vif.clk_i);
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
      disable fork;
       reset();
    end
  endtask
        
endclass