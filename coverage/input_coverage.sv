class input_coverage;
  
  input_transaction input_trans_covered;
  
  //pentru a se putea vedea valoarea de coverage pentru fiecare element trebuie create mai multe grupuri de coverage, sau trebuie creata o functie de afisare proprie
  covergroup transaction_cg;
    //linia de mai jos este adaugata deoarece, daca sunt mai multe instante pentru care se calculeaza coverage-ul, noi vrem sa stim pentru fiecare dintre ele, separat, ce valoare avem.
    option.per_instance = 1;
    
    // adaugati adresele tuturor registrilor pe care ii aveti in DUT (sunt documentati in specificatie)
    
     // Directia vantului
    wind_dir_cp: coverpoint input_trans_covered.wind_dir_i {
      bins N  = {[676:720], [0:45]};   // 338.0°–360.0° + 0.0°–22.5°
      bins NE = {[46:135]};            // 23.0°–67.5°
      bins E  = {[136:225]};           // 68.0°–112.5°
      bins SE = {[226:315]};           // 113.0°–157.5°
      bins S  = {[316:405]};           // 158.0°–202.5°
      bins SV = {[406:495]};           // Sud-Vest
      bins V  = {[496:585]};           // Vest
      bins NV = {[586:675]};           // Nord-Vest
    }

    //Viteza vantului
    wind_speed_cp: coverpoint input_trans_covered.wind_speed_i {
      bins lowest_value= {0};
      bins highest_value = {600};

      bins calm     = {[1:50]};
      bins moderate = {[51:300]};
      bins strong_wind = {[301:599]};

    }
    
    //Temperatura
   temp_cp: coverpoint input_trans_covered.temp_value_i {
     bins coldest_value = {0};
     bins hottest_value = {100};

     bins cold   = {[1:30]};
     bins normal = {[31:70]};
     bins warm   = {[71:99]};

   }

  //RPM
   rpm_cp: coverpoint input_trans_covered.rpm_value_i {

     bins stopped = {0};

     bins low     = {[1:80]};
     bins nominal = {[81:200]};
     bins high    = {[201:300]};
     bins extreme = {[301:350]};

   }
    
    //Unghiul palelor
    blade_angle_cp: coverpoint input_trans_covered.blade_angle_i {
      
      bins lowest_value  = {0};
      bins highest_value = {180};

      bins fully_open        = {[1:45]};
      bins open              = {[46:90]};
      bins partially_closed  = {[91:135]};
      bins nearly_closed     = {[136:179]};
    }

   //Unghiul nacelei  
    yaw_angle_cp: coverpoint input_trans_covered.yaw_angle_i {

      bins low  = {[0:240]};
      bins mid  = {[241:480]};
      bins high = {[481:720]};
    }

  endgroup

  //se creaza grupul de coverage; ATENTIE! Fara functia de mai jos, grupul de coverage nu va putea esantiona niciodata date deoarece pana acum el a fost doar declarat, nu si creat
  function new();
    transaction_cg = new();
  endfunction
  
  task sample(input_transaction input_trans_covered); 
  	this.input_trans_covered = input_trans_covered; 
  	transaction_cg.sample(); 
  endtask:sample   
  
  function void print_coverage();

    $display("Wind dir coverage   = %.2f%%", transaction_cg.wind_dir_cp.get_coverage());
    $display("Wind speed coverage = %.2f%%", transaction_cg.wind_speed_cp.get_coverage());
    $display("Temp coverage       = %.2f%%", transaction_cg.temp_cp.get_coverage());
    $display("RPM coverage        = %.2f%%", transaction_cg.rpm_cp.get_coverage());
    $display("Blade coverage      = %.2f%%", transaction_cg.blade_angle_cp.get_coverage());
    $display("Yaw coverage        = %.2f%%", transaction_cg.yaw_angle_cp.get_coverage());
    $display("TOTAL COVERAGE      = %.2f%%", transaction_cg.get_coverage());



  endfunction
  
  //o alta modalitate de a incheia declaratia unei clase este sa se scrie "endclass: numele_clasei"; acest lucru este util mai ales cand se declara mai multe clase in acelasi fisier; totusi, se recomanda ca fiecare fisier sa nu contina mai mult de o declaratie a unei clase
endclass: input_coverage

