class input_generator;
  
  //clasa contine doua atribute de tipul "transaction"
  rand input_transaction trans;
  input_transaction tr;
  
  //repeat_count arata numarul de tranzactii care vor fi generate
  int  repeat_count;
  
  //tipul de date mailbox, care poate fi vazut ca o structura de tip coada, reprezinta "portul" prin care generatorul trimite date driver-ului.
  //mailbox, to generate and send the packet to driver
  mailbox gen2driv;
  
  //declararea unui eveniment
  event ended;
   
  //constructor
  function new(mailbox gen2driv,event ended);
    //getting the mailbox handle from env, in order to share the transaction packet between the generator and driver, the same mailbox is shared between both.
    this.gen2driv = gen2driv;
    this.ended    = ended;
    trans = new();
  endfunction
  
  //generatorul aleatorizeaza si transmite spre exterior prin "portul" de tip mailbox continutul tranzactiilor (al caror numar este egal cu repeat_count)
  //main task, generates(create and randomizes) the repeat_count number of transaction packets and puts into mailbox
  task main();
    repeat(repeat_count) begin
    	if( !trans.randomize() ) 
          $fatal(1, "Gen:: trans randomization failed");      
    	tr = trans.do_copy();
    	gen2driv.put(tr);
    end
    //se semnaleaza sfarsitul transmiterii datelor de catre generator
    -> ended; 
  endtask
  
  task generate_single_transaction(  
    bit [9:0] wind_dir    = 10'd120,
    bit [9:0] wind_speed  = 10'd100,
    bit [6:0] temp_value  = 7'd50,
    bit [8:0] rpm_value   = 9'd100,
    bit [7:0] blade_angle = 8'd90,
    bit [9:0] yaw_angle   = 10'd120
  );

    if (!trans.randomize() with {
      wind_dir_i    == wind_dir;
      wind_speed_i  == wind_speed;
      temp_value_i  == temp_value;
      rpm_value_i   == rpm_value;
      blade_angle_i == blade_angle;
      yaw_angle_i   == yaw_angle;
    }) begin
      $fatal(1, "Gen:: trans randomization failed");
    end

    tr = trans.do_copy();
    gen2driv.put(tr);

  endtask

endclass