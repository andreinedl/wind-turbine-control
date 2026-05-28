//-------------------------------------------------------------------------
//						www.verificationguide.com 
//-------------------------------------------------------------------------

//aici se declara tipul de data folosit pentru a stoca datele vehiculate intre generator si driver; monitorul, de asemenea, preia datele de pe interfata, le recompune folosind un obiect al acestui tip de data, si numai apoi le proceseaza
class output_transaction;
  //se declara atributele clasei
  //campurile declarate cu cuvantul cheie rand vor primi valori aleatoare la aplicarea functiei randomize()
  rand bit [8-1:0]  blade_pos_o;
  rand bit [10-1:0] yaw_pos_o;  
  rand bit          heat_o;
  rand bit          em_brake_o;
  rand bit [3:0]    error_feedback_o;
  
  // Constrangerile asigura ca, daca folosim randomizarea pe acest obiect, 
  // valorile generate se vor incadra in limitele DUT-ului
  constraint blade_pos_c { 
    blade_pos_o inside {[0:180]}; // 180 = 90 de grade
  }
  
  constraint yaw_pos_c { 
    yaw_pos_o inside {[0:720]};   // 720 = 360 de grade 
  }

  constraint error_c {
    error_feedback_o inside {[0:15]};
  }
  
  //aceasta functie este apelata dupa aplicarea functiei randomize() asupra obiectelor apartinand acestei clase
  //aceasta functie afiseaza valorile aleatorizate ale atributelor clasei
  function void post_randomize();
    $display("--------- post_randomize ------");
    $display("\t blade_pos_o = %0d", blade_pos_o);
    $display("\t yaw_pos_o   = %0d", yaw_pos_o);
    $display("\t heat_o      = %0b", heat_o);
    $display("\t em_brake_o  = %0b", em_brake_o);
    $display("\t error_feedback_o  = %0b", error_feedback_o);
    $display("----------------------------------------------");
  endfunction
  
  //operator de copiere a unui obiect intr-un alt obiect (deep copy)
  //cand trimitem un obiect printr-un mailbox, trimitem de fapt un pointer
  function output_transaction do_copy();
    output_transaction output_trans;
    output_trans = new();
    output_trans.blade_pos_o      = this.blade_pos_o;
    output_trans.yaw_pos_o        = this.yaw_pos_o;
    output_trans.heat_o           = this.heat_o;
    output_trans.em_brake_o       = this.em_brake_o;
    output_trans.error_feedback_o = this.error_feedback_o;
    return output_trans;
  endfunction

endclass