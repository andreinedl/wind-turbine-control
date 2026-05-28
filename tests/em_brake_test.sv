//-------------------------------------------------------------------------
// Scenariu de verificare: activarea semnalului emergency stop
//-------------------------------------------------------------------------

program em_brake_test(
  input_interface  input_intf,
  output_interface output_intf,
  server_interface server_intf
);

  class emergency_stop_trans extends input_transaction;
    // Folosim o variabila pentru a stoca in ce stadiu al testului ne aflam
    // la fiecare noua generare a unei tranzactii (deoarece generatorul apeleaza randomize() repetat).
    static int unsigned scenario_idx;

    // Suprascriem functia pre_randomize() pentru a nu mai avea generare aleatorie
    // dezactivam randomizarea si si setam noi valori manual
    function void pre_randomize();
      // dezactivare randomizare
      wind_dir_i.rand_mode(0);
      wind_speed_i.rand_mode(0);
      temp_value_i.rand_mode(0);
      rpm_value_i.rand_mode(0);
      blade_angle_i.rand_mode(0);
      yaw_angle_i.rand_mode(0);

      // setare valori
      wind_dir_i       = 10'd180;
      wind_speed_i     = 10'd120;
      temp_value_i     = 7'd50;
      rpm_value_i      = 9'd350; // Forteaza activarea emergency stop.
      blade_angle_i    = 8'd90;
      yaw_angle_i      = 10'd180;

      // corner cases
      // pastram mereu RPM-ul la pragul limita (350) pentru a verifica activarea franei de urg.
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
    // Inlocuim tranzactia din generator cu tranzactia mostenita care genereaza doar cazurile de frana de urgenta.
    env.gen.trans = scen_tr;

    // Setam generatorul sa produca 6 repetari
    env.gen.repeat_count = 6;

    env.run();
  end
endprogram