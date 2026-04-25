//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
//driverul preia datele de la generator, la nivel abstract, si le trimite DUT-ului conform protocolului de comunicatie pe interfata respectiva
//gets the packet from generator and drive the transaction packet items into interface (interface is connected to DUT, so the items driven into interface signal will get driven in to DUT) 

//se declara macro-ul INPUT_DRIV_IF care va reprezenta interfata pe care driverul va trimite date DUT-ului
`define INPUT_DRIV_IF input_vif.driver_cb
class input_driver;
  
  //used to count the number of transactions
  int no_transactions;
  
  //creating virtual interface handle
  virtual input_interface input_vif;
  
  //se creaza portul prin care driverul primeste datele la nivel abstract de la DUT
  //creating mailbox handle
  mailbox gen2driv;
  
  //constructor
  function new(virtual input_interface input_vif,mailbox gen2driv);
    //cand se creaza driverul, interfata pe care acesta trimite datele este conectata la interfata reala a DUT-ului
    //getting the interface
    this.input_vif = input_vif;
    //getting the mailbox handles from  environment 
    this.gen2driv = gen2driv;
  endfunction
  
  //Reset task, Reset the Interface signals to default/initial values
  task reset;
    wait(!input_vif.rst_ni);
    $display("--------- [DRIVER] Reset Started ---------");
    `INPUT_DRIV_IF.wind_dir_i <= 0;
    `INPUT_DRIV_IF.wind_speed_i <= 0;  
    `INPUT_DRIV_IF.temp_value_i <= 0;
    `INPUT_DRIV_IF.rpm_value_i <= 0;
    `INPUT_DRIV_IF.blade_angle_i <= 0;
    `INPUT_DRIV_IF.yaw_angle_i <= 0;
    
    wait(input_vif.rst_ni);
    $display("--------- [DRIVER] Reset Ended ---------");
  endtask
  
  //drives the transaction items to interface signals
  task drive;
    input_transaction trans;
      
    //se asteapta ca modulul sa iasa din reset
    wait(input_vif.rst_ni); // reset activ in 0
    
    //daca nu are date de la generator, driverul ramane cu executia la linia de mai jos, pana cand primeste respectivele date
      gen2driv.get(trans);
      $display("--------- [DRIVER-TRANSFER: %0d] ---------",no_transactions);
      @(posedge input_vif.clk_i);
        `INPUT_DRIV_IF.wind_dir_i    <= trans.wind_dir_i;
        `INPUT_DRIV_IF.wind_speed_i  <= trans.wind_speed_i;
        `INPUT_DRIV_IF.temp_value_i  <= trans.temp_value_i;
        `INPUT_DRIV_IF.rpm_value_i   <=  trans.rpm_value_i;
        `INPUT_DRIV_IF.blade_angle_i <= trans.blade_angle_i;
        `INPUT_DRIV_IF.yaw_angle_i   <= trans.yaw_angle_i; 
      $display("-----------------------------------------");
      no_transactions++;
  endtask
  
    
  //Cele doua fire de executie de mai jos ruleaza in paralel. Dupa ce primul dintre ele se termina al doilea este intrerupt automat. Daca se activeaza reset-ul, nu se mai transmit date. 
  task main;
    forever begin
      fork
        //Thread-1: Waiting for reset
        begin
          wait(!input_vif.rst_ni); //Reset activ in 0
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