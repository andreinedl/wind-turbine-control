//-------------------------------------------------------------------------
// Scenariu de verificare: activarea semnalului emergency stop
//-------------------------------------------------------------------------

program em_brake_test(
  input_interface  input_intf,
  output_interface output_intf,
  server_interface server_intf
);

  class emergency_stop_trans extends input_transaction;
    static int unsigned scenario_idx;

    function void pre_randomize();
      // Scenariul este directionat: valorile sunt impuse explicit.
      wind_dir_i.rand_mode(0);
      wind_speed_i.rand_mode(0);
      temp_value_i.rand_mode(0);
      rpm_value_i.rand_mode(0);
      blade_angle_i.rand_mode(0);
      yaw_angle_i.rand_mode(0);

      wind_dir_i       = 10'd180;
      wind_speed_i     = 10'd120;
      temp_value_i     = 7'd50;
      rpm_value_i      = 9'd350; // Forteaza activarea emergency stop.
      blade_angle_i    = 8'd90;
      yaw_angle_i      = 10'd180;

      case (scenario_idx)
        0: wind_speed_i = 10'd600; // Valoare mare la viteza vantului
        1: wind_speed_i = 10'd0;   // Valoare mica pentru viteza vantului
        2: wind_dir_i   = 10'd720; // Valoare mare pentru directia vantului
        3: wind_dir_i   = 10'd0;   // Valoare mica pentru directia vantului
        4: temp_value_i = 7'd0;    // Valoare mica temperatura intrare
        5: temp_value_i = 7'd100;  // Valoare mare temperatura intrare
        default: ;
      endcase

      scenario_idx++;
    endfunction
  endclass

  environment env;
  emergency_stop_trans scen_tr;

  initial begin
    env = new(input_intf, output_intf, server_intf);

    scen_tr = new();
    env.gen.trans = scen_tr;

    env.gen.repeat_count = 6;

    env.run();
  end
endprogram