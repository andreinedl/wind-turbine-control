//prin coverage, putem vedea ce situatii (de exemplu, ce tipuri de tranzactii) au fost generate in simulare; astfel putem masura stadiul la care am ajuns cu verificarea
class output_coverage;
  
  output_transaction output_trans_covered;
  
  // Variabile interne pentru a masura timpul (in cicli de ceas) cat persista eroarea
  int wait_cycles_counter = 0;
  int last_wait_cycles = 0;
  bit is_error_active = 0;
  
  //pentru a se putea vedea valoarea de coverage pentru fiecare element trebuie create mai multe grupuri de coverage, sau trebuie creata o functie de afisare proprie
  covergroup transaction_cg;
    //linia de mai jos este adaugata deoarece, daca sunt mai multe instante pentru care se calculeaza coverage-ul, noi vrem sa stim pentru fiecare dintre ele, separat, ce valoare avem.
    option.per_instance = 1;

    // coverage point pentru pozitia palelor
    blade_pos_cp: coverpoint output_trans_covered.blade_pos_o {
      bins low_wind     = {0};          // palele sunt maxim deschide - la vant cu viteza foarte redusa
      bins range[6]     = {[1:179]};    // 6 range uri egale intermediare
      bins high_wind    = {180};        // palele sunt inchise - la vant cu viteza foarte mare
      illegal_bins out_of_range = {[181:$]};    // valori peste limita
    }
    
    yaw_pos_cp: coverpoint output_trans_covered.yaw_pos_o {
      bins zero_deg      = {0};         // nacela e la 0 grade
      bins range[6]      = {[1:719]};   // 6 range-uri egale intermediare
      bins full_rotation = {720};       // nacela e la 360 de grade
      illegal_bins out_of_range  = default; //{[721:$]};   // valori peste limita
    }

    heat_cp: coverpoint output_trans_covered.heat_o {
      bins disabled = {0};
      bins enabled  = {1};
    }

    em_brake_cp: coverpoint output_trans_covered.em_brake_o {
      bins disabled = {0};
      bins enabled  = {1};
    }

    error_feedback_cp: coverpoint output_trans_covered.error_feedback_o {
      bins no_error    = {4'b0000};
      bins em_brake    = {4'b0001};
      bins yaw_error   = {4'b0010};
      bins blade_error = {4'b0100};
      bins temp_error  = {4'b1000};
      bins multi_error[] = {[4'b0011:4'b1111]};
    }

    error_trans_cp: coverpoint output_trans_covered.error_feedback_o {
      bins error_asserted = (0 => [1:15]);
      bins error_deasserted = ([1:15] => 0);
    }

    wait_times_cp: coverpoint last_wait_cycles {
      bins fast_recovery   = {[1:5]};
      bins medium_recovery = {[6:15]};
      bins slow_recovery   = {[16:50]};
      bins timeout         = {[51:$]};
    }

    heat_x_brake: cross em_brake_cp, heat_cp;
    
  endgroup

  //se creaza grupul de coverage; ATENTIE! Fara functia de mai jos, grupul de coverage nu va putea esantiona niciodata date deoarece pana acum el a fost doar declarat, nu si creat
  function new();
    transaction_cg = new();
  endfunction
  
  task sample(output_transaction output_trans_covered); 
  	this.output_trans_covered = output_trans_covered; 

    // Calculam timpii de asteptare pentru eroare
    if (output_trans_covered.error_feedback_o != 0) begin
      wait_cycles_counter++;
      is_error_active = 1;
    end else if (output_trans_covered.error_feedback_o == 0 && is_error_active) begin
      last_wait_cycles = wait_cycles_counter;
      is_error_active = 0;
      wait_cycles_counter = 0;
    end

  	transaction_cg.sample(); 
  endtask:sample   
  
  function print_coverage();
    $display ("Blade position coverage = %.2f%%", transaction_cg.blade_pos_cp.get_coverage());
    $display ("Yaw position coverage = %.2f%%", transaction_cg.yaw_pos_cp.get_coverage());
    $display ("Heat coverage = %.2f%%", transaction_cg.heat_cp.get_coverage());
    $display ("Emergency brake coverage = %.2f%%", transaction_cg.em_brake_cp.get_coverage());
    $display ("Error feedback coverage = %.2f%%", transaction_cg.error_feedback_cp.get_coverage());
    $display ("Error transitions coverage = %.2f%%", transaction_cg.error_trans_cp.get_coverage());
    $display ("Error wait times coverage = %.2f%%", transaction_cg.wait_times_cp.get_coverage());
    $display ("Overall coverage = %.2f%%", transaction_cg.get_coverage());
  endfunction
  
  //o alta modalitate de a incheia declaratia unei clase este sa se scrie "endclass: numele_clasei"; acest lucru este util mai ales cand se declara mai multe clase in acelasi fisier; totusi, se recomanda ca fiecare fisier sa nu contina mai mult de o declaratie a unei clase
endclass: output_coverage
