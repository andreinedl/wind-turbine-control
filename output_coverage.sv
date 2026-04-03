//prin coverage, putem vedea ce situatii (de exemplu, ce tipuri de tranzactii) au fost generate in simulare; astfel putem masura stadiul la care am ajuns cu verificarea
class output_coverage;
  
  transaction trans_covered;
  
  //pentru a se putea vedea valoarea de coverage pentru fiecare element trebuie create mai multe grupuri de coverage, sau trebuie creata o functie de afisare proprie
  covergroup transaction_cg;
    //linia de mai jos este adaugata deoarece, daca sunt mai multe instante pentru care se calculeaza coverage-ul, noi vrem sa stim pentru fiecare dintre ele, separat, ce valoare avem.
    option.per_instance = 1;

    // coverage point pentru pozitia palelor
    blade_pos_cp: coverpoint trans_covered.blade_pos_o {
      bins low_wind     = {0};          // palele sunt maxim deschide - la vant cu viteza foarte redusa
      bins range[6]     = {[1:179]};    // 6 range uri egale intermediare
      bins high_wind    = {180};        // palele sunt inchise - la vant cu viteza foarte mare
      bins out_of_range = {[181:$]};    // valori peste limita
    }
    
    yaw_pos_cp: coverpoint trans_covered.yaw_pos_o {
      bins zero_deg      = {0};         // nacela e la 0 grade
      bins range[6]      = {[1:719]};   // 6 range-uri egale intermediare
      bins full_rotation = {720};       // nacela e la 360 de grade
      bins out_of_range  = {[721:$]};   // valori peste limita
    }

    heat_cp: coverpoint trans_covered.heat_o {
      bins disabled = {0};
      bins enabled  = {1};
    }

    em_brake_cp: coverpoint trans_covered.em_brake_o {
      bins disabled = {0};
      bins enabled  = {1};
    }

    heat_x_brake: cross em_brake_cp, heat_cp;
    
  endgroup
  //se creaza grupul de coverage; ATENTIE! Fara functia de mai jos, grupul de coverage nu va putea esantiona niciodata date deoarece pana acum el a fost doar declarat, nu si creat
  function new();
    transaction_cg = new();
  endfunction
  
  task sample(transaction trans_covered); 
  	this.trans_covered = trans_covered; 
  	transaction_cg.sample(); 
  endtask:sample   
  
  function print_coverage();
    $display ("Blade position coverage = %.2f%%", transaction_cg.blade_pos_cp.get_coverage());
    $display ("Yaw position coverage = %.2f%%", transaction_cg.yaw_pos_cp.get_coverage());
    $display ("Heat coverage = %.2f%%", transaction_cg.heat_cp.get_coverage());
    $display ("Emergency brake coverage = %.2f%%", transaction_cg.em_brake_cp.get_coverage());
    $display ("Overall coverage = %.2f%%", transaction_cg.get_coverage());
  endfunction
  
  //o alta modalitate de a incheia declaratia unei clase este sa se scrie "endclass: numele_clasei"; acest lucru este util mai ales cand se declara mai multe clase in acelasi fisier; totusi, se recomanda ca fiecare fisier sa nu contina mai mult de o declaratie a unei clase
endclass: output_coverage

