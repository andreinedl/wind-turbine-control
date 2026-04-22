
class input_transaction;
  rand bit [9:0]  wind_dir_i ;
  rand bit [9:0]  wind_speed_i;
  rand bit [7:0]  temp_value_i;
  rand bit [8:0]  rpm_value_i ;
  rand bit [3:0]  error_feedback_i;
  rand bit [7:0]  blade_angle_i;
  rand bit [9:0]  yaw_angle_i;
  
  // directia vantului: 0 - 720 (0 - 360 grade) (precizie 0,5 grade)
constraint wind_dir_c {
  wind_dir_i inside {[0:720]};
}

// viteza vantului: 0 - 600 (0 - 60 m/s)
constraint wind_speed_c {
  wind_speed_i inside {[0:600]};
}

// temperatura: 0 - 100 (-25°C -> 75°C)
constraint temp_c {
  temp_value_i inside {[0:100]};
}

// turatia: 0 - 350 RPM
constraint rpm_c {
  rpm_value_i inside {[0:350]};
}

// feedback eroare (4 biti)
constraint error_c {
  error_feedback_i inside {[0:15]};
}

// unghi palete: 0 - 180 (0.5° rezolutie)
constraint blade_angle_c {
  blade_angle_i inside {[0:180]};
}

// unghi nacela: 0 - 720 (0.5° rezolutie)
constraint yaw_angle_c {
  yaw_angle_i inside {[0:720]};
}
  
 
  function void post_randomize();
  $display("--------- [Trans] post_randomize ------");

  $display("wind_dir_i       = %0d", wind_dir_i);
  $display("wind_speed_i     = %0d", wind_speed_i);
  $display("temp_value_i     = %0d", temp_value_i);
  $display("rpm_value_i      = %0d", rpm_value_i);
  $display("error_feedback_i = %0d", error_feedback_i);
  $display("blade_angle_i    = %0d", blade_angle_i);
  $display("yaw_angle_i      = %0d", yaw_angle_i);

  $display("---------------------------------------");
endfunction
  
  //operator de copiere a unui obiect intr-un alt obiect (deep copy)
  function input_transaction do_copy();
    input_transaction input_trans;
    input_trans = new();
    input_trans.wind_dir_i  = this.wind_dir_i;
    input_trans.wind_speed_i = this.wind_speed_i;
    input_trans.temp_value_i = this.temp_value_i;
    input_trans.rpm_value_i = this.rpm_value_i;
    input_trans.error_feedback_i = this.error_feedback_i;
    input_trans.blade_angle_i = this.blade_angle_i;
    input_trans.yaw_angle_i = this.yaw_angle_i;
    /*input_trans.clk_i = this.clk_i;
    input_trans.rst_ni = this.rst_ni;*/ //CLOCK SI RESET NU TREBUIESC COPIATE

    return input_trans;
  endfunction
endclass