interface server_interface(input logic clk_i, rst_ni);
  logic [31:0] logs_o;       // 32 biți, biți împărțiți
  
  // Semnale APB conduse de Master
  logic        paddr;
  logic        psel;    
  logic        penable; 
  logic        pwrite;  
  logic [31:0] pwdata;  
  
  // Semnale APB primite de la Slave 
  logic        pready;  
  logic        pslverr; 

  // Clocking block pentru Driver
  clocking driver_cb @(posedge clk_i);
    default input #1 output #1;
    // Driver-ul (Slave) generează răspunsurile către Master
    output pready, pslverr;
    // Driver-ul (Slave) monitorizează comenzile de la DUT
    input  paddr, psel, penable, pwrite, pwdata, logs_o; 
  endclocking

  // Monitorul rămâne pasiv, observă tot traficul
  clocking monitor_cb @(posedge clk_i);
    default input #1 output #1;
    input paddr, psel, penable, pwrite, pwdata;
    input pready, pslverr, logs_o;
  endclocking

  // Modport pentru Slave Driver
  modport SLAVE_DRIVER (clocking driver_cb, input clk_i, rst_ni);
  
  // Modport pentru Monitor
  modport MONITOR (clocking monitor_cb, input clk_i, rst_ni);

  // Modport pentru DUT
  modport DUT (
    output paddr, psel, penable, pwrite, pwdata, 
    input  pready, pslverr,              
    output logs_o,                       
    input  clk_i, rst_ni
  );

//trecerea de la primul ciclu la al doilea ciclu al tranzactiei
  property p_apb_penable_setup;
    @(posedge clk_i) disable iff (!rst_ni)
    psel && !penable |=> penable;
  endproperty
  assert_apb_penable_setup: assert property (p_apb_penable_setup) 
                            else $error("APB_ERR: Master-ul trebuie sa ridice PENABLE la un ciclu dupa PSEL");
P_APB_PENABLE_SETUP_C: cover property (p_apb_penable_setup);//ne asiguram ca proprietatea a fost accesata macar o data

//paddr trebuie sa ramana stabila si valida pe toata durata tranzactiei
  property p_apb_addr_stable;
    @(posedge clk_i) disable iff (!rst_ni)
    psel |-> $stable(paddr) && paddr !=='x && paddr !=='z; // !$unknown(paddr)
  endproperty
  assert_apb_addr_stable: assert property (p_apb_addr_stable) 
                          else $error("APB_ERR: Master-ul a schimbat PADDR in timp ce PSEL este activ");
P_APB_ADDR_STABLE_C: cover property (p_apb_addr_stable);//ne asiguram ca proprietatea a fost accesata macar o data


//dupa ce s-a terminat tranzactia, toate semnalele de protocol se duc in valoarea 0
  property p_apb_psel_hold;
    @(posedge clk_i) disable iff (!rst_ni)
    (psel && penable && pready) |=> (!psel && !penable && !pready);
  endproperty
  assert_apb_hold: assert property (p_apb_psel_hold) 
                   else $error("APB_ERR: Master-ul a dezactivat PSEL/PENABLE inainte ca Slave-ul sa dea PREADY");
P_APB_PSEL_HOLD_C: cover property (p_apb_psel_hold);//ne asiguram ca proprietatea a fost accesata macar o data

//penable=1 poate avea loc doar in cadrul unei tranzactii valide, asadar psel trebuie sa fie obligatoriu activ 
  property p_apb_pready;
    @(posedge clk_i) disable iff (!rst_ni)
    (penable) |-> (psel);
  endproperty
  assert_apb_pready: assert property (p_apb_pready) 
                   else $error("APB_ERR: PREADY nu este 1 cand PENABLE este 1.");
P_APB_PREADY_C: cover property (p_apb_pready);//ne asiguram ca proprietatea a fost accesata macar o data				   

//pready este de tip puls
  property p_apb_end;
    @(posedge clk_i) disable iff (!rst_ni)
    pready |=> !penable;
  endproperty
  assert_apb_end: assert property (p_apb_end) 
                  else $error("APB_ERR: Master-ul nu a coborat PENABLE dupa finalizarea tranzactiei (PREADY=1)");
				  
P_APB_END_C: cover property (p_apb_end);//ne asiguram ca proprietatea a fost accesata macar o data

// PENABLE trebuie sa fie 0 in primul ciclu al tranzactiei 
  property p_apb_penable;
	@(posedge clk_i) disable iff (!rst_ni)
	$rose(psel) |-> penable ==0;
  endproperty
  assert_apb_penable: assert property (p_apb_penable)
                      else $error("APB_ERR: PENABLE trebuie sa fie 0 cand PSEL tocmai a devenit 1.")
				  
P_APB_PENABLE_C: cover property (p_apb_penable);//ne asiguram ca proprietatea a fost accesata macar o data
	
// pwdata trebuie sa ramana stabil pe durata fazei de access la o scriere	
   property p_apb_pwdata_stable;
	@(posedge clk_i) disable iff (!rst_ni)
    psel && pwrite |-> $stable(pwdata);
  endproperty
  assert_apb_pwdata_stable: assert property (p_apb_pwdata_stable)
                            else $error("APB_ERR: Master-ul a modificat datele in timp ce tranzactia astepta PREADY.")	
							
P_APB_PWDATA_STABLE_C: cover property (p_apb_pwdata_stable);//ne asiguram ca proprietatea a fost accesata macar o data			 
				  
endinterface
