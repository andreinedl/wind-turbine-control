interface server_interface(input logic clk_i, rst_ni);
   // Semnale APB conduse de Master
  logic        paddr;   // Adresa registrului accesat 
  logic        psel;    // Selectează Slave-ul
  logic        penable;  // Faza de acces (ciclul 2 al tranzacției)
  logic        pwrite;   // 1=scriere , 0=citire
  logic [31:0] pwdata;   // Date de scris 
  
  // Semnale APB primite de la Slave 
  logic        pready;  // Slave-ul este gata să finalizeze tranzacția
  logic        pslverr;  // Slave-ul raportează o eroare

  // Clocking Block pentru Driver
  clocking driver_cb @(posedge clk_i);
    default input #1 output #1;
    output pready, pslverr;  // Driver-ul (Slave) generează răspunsurile către Master
    input  paddr, psel, penable, pwrite, pwdata;   // Driver-ul (Slave) monitorizează comenzile de la DUT
  endclocking

  // Monitorul rămâne pasiv, observă tot traficul
  clocking monitor_cb @(posedge clk_i);
    default input #1 output #1;
    input paddr, psel, penable, pwrite, pwdata;
    input pready, pslverr;
  endclocking

  // Modport pentru Driver
  modport SLAVE_DRIVER (clocking driver_cb, input clk_i, rst_ni);
  
  // Modport pentru Monitor
  modport MONITOR (clocking monitor_cb, input clk_i, rst_ni);

  // Modport pentru DUT - conectează direct DUT-ul la interfață
  modport DUT (
    output paddr, psel, penable, pwrite, pwdata, 
    input  pready, pslverr,                                    
    input  clk_i, rst_ni
  );

// Trecerea de la primul ciclu la al doilea ciclu al tranzacției 
// (dacă în primul ciclul psel=1 și penable=0, atunci în ciclul următor penable=1) 
  property p_apb_penable_setup;
    @(posedge clk_i) disable iff (!rst_ni)
    psel && !penable |=> penable;
  endproperty
  assert_apb_penable_setup: assert property (p_apb_penable_setup) 
                            else $error("APB_ERR: Master-ul trebuie sa ridice PENABLE la un ciclu dupa PSEL");
P_APB_PENABLE_SETUP_C: cover property (p_apb_penable_setup);//ne asigurăm că proprietatea a fost accesată măcar o dată

// paddr trebuie să rămână stabilă și validă pe toată durata tranzacției
// (pe toată durata cât psel=1, adresa nu se schimbă)
  property p_apb_addr_stable;
    @(posedge clk_i) disable iff (!rst_ni)
    psel |-> $stable(paddr) && paddr !=='x && paddr !=='z; 
  endproperty
  assert_apb_addr_stable: assert property (p_apb_addr_stable) 
                          else $error("APB_ERR: Master-ul a schimbat PADDR in timp ce PSEL este activ");
P_APB_ADDR_STABLE_C: cover property (p_apb_addr_stable);//ne asigurăm că proprietatea a fost accesată măcar o dată

// După ce s-a terminat tranzacția, toate semnalele de protocol se duc în valoarea 0
  property p_apb_psel_hold;
    @(posedge clk_i) disable iff (!rst_ni)
    (psel && penable && pready) |=> (!psel && !penable && !pready);
  endproperty
  assert_apb_hold: assert property (p_apb_psel_hold) 
                   else $error("APB_ERR: Master-ul a dezactivat PSEL/PENABLE inainte ca Slave-ul sa dea PREADY");
P_APB_PSEL_HOLD_C: cover property (p_apb_psel_hold);//ne asigurăm că proprietatea a fost accesată măcar o dată

// penable=1 poate avea loc doar în cadrul unei tranzacții valide, așadar psel trebuie să fie obligatoriu activ 
  property p_apb_pready;
    @(posedge clk_i) disable iff (!rst_ni)
    (penable) |-> (psel);
  endproperty
  assert_apb_pready: assert property (p_apb_pready) 
                   else $error("APB_ERR: PREADY nu este 1 cand PENABLE este 1.");
P_APB_PREADY_C: cover property (p_apb_pready);//ne asigurăm că proprietatea a fost accesată măcar o dată				   

// Dacă slave-ul semnalează pready=1, în ciclul următor penable trebuie să fie 0
// (pready este de tip puls)
  property p_apb_end;
    @(posedge clk_i) disable iff (!rst_ni)
    pready |=> !penable;
  endproperty
  assert_apb_end: assert property (p_apb_end) 
                  else $error("APB_ERR: Master-ul nu a coborat PENABLE dupa finalizarea tranzactiei (PREADY=1)");
P_APB_END_C: cover property (p_apb_end);//ne asigurăm că proprietatea a fost accesată măcar o dată

// PENABLE trebuie să fie 0 în primul ciclu al tranzacției 
  property p_apb_penable;
	@(posedge clk_i) disable iff (!rst_ni)
	$rose(psel) |-> penable ==0;
  endproperty
  assert_apb_penable: assert property (p_apb_penable)
                      else $error("APB_ERR: PENABLE trebuie sa fie 0 cand PSEL tocmai a devenit 1.");
P_APB_PENABLE_C: cover property (p_apb_penable);//ne asigurăm că proprietatea a fost accesată măcar o dată
	
// pwdata trebuie să rămână stabil pe durata fazei de access la o scriere	(datele nu se schimbă)
   property p_apb_pwdata_stable;
	@(posedge clk_i) disable iff (!rst_ni)
    psel && penable && pwrite |-> $stable(pwdata);
  endproperty
  assert_apb_pwdata_stable: assert property (p_apb_pwdata_stable)
                            else $error("APB_ERR: Master-ul a modificat datele in timp ce tranzactia astepta PREADY.");						
P_APB_PWDATA_STABLE_C: cover property (p_apb_pwdata_stable);//ne asigurăm că proprietatea a fost accesată măcar o dată			 
				  
endinterface
