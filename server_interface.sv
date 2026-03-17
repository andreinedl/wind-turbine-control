interface server_interface(input logic clk_i, rst_ni);
  logic [31:0] logs_o;       // 32 biți, biți împărțiți
  logic        valid_o;      // 1 bit: valid server logs
  
  // Semnale APB conduse de Master
  logic [31:0] paddr;   
  logic        psel;    
  logic        penable; 
  logic        pwrite;  
  logic [31:0] pwdata;  
  
  // Semnale APB primite de la Slave
  logic [31:0] prdata;  
  logic        pready;  
  logic        pslverr; 

  // Clocking block pentru Driver
  clocking driver_cb @(posedge clk_i);
    default input #1 output #1;
    // Driver-ul (Slave) generează răspunsurile către Master
    output prdata, pready, pslverr;
    // Driver-ul (Slave) monitorizează comenzile de la DUT
    input  paddr, psel, penable, pwrite, pwdata, logs_o, valid_o; 
  endclocking

  // Monitorul rămâne pasiv, observă tot traficul
  clocking monitor_cb @(posedge clk_i);
    default input #1 output #1;
    input paddr, psel, penable, pwrite, pwdata;
    input prdata, pready, pslverr, logs_o, valid_o;
  endclocking

  // Modport pentru Slave Driver
  modport SLAVE_DRIVER (clocking driver_cb, input clk_i, rst_ni);
  
  // Modport pentru Monitor
  modport MONITOR (clocking monitor_cb, input clk_i, rst_ni);

  // Modport pentru DUT
  modport DUT (
    output paddr, psel, penable, pwrite, pwdata, // Ieșiri: Controlul magistralei
    input  prdata, pready, pslverr,              // Intrări: Răspunsul de la periferic
    output logs_o, valid_o,                      // Ieșiri: Status server
    input  clk_i, rst_ni
  );

  property p_apb_penable_setup;
    @(posedge clk_i) disable iff (!rst_ni)
    psel && !penable |=> penable;
  endproperty
  assert_apb_penable: assert property (p_apb_penable_setup) 
                      else $error("APB_ERR: Master-ul trebuie sa ridice PENABLE la un ciclu dupa PSEL");

  property p_apb_addr_stable;
    @(posedge clk_i) disable iff (!rst_ni)
    psel |-> $stable(paddr);
  endproperty
  assert_apb_addr_stable: assert property (p_apb_addr_stable) 
                          else $error("APB_ERR: Master-ul a schimbat PADDR in timp ce PSEL este activ");

  property p_apb_psel_hold;
    @(posedge clk_i) disable iff (!rst_ni)
    (psel && penable && !pready) |=> (psel && penable);
  endproperty
  assert_apb_hold: assert property (p_apb_psel_hold) 
                   else $error("APB_ERR: Master-ul a dezactivat PSEL/PENABLE inainte ca Slave-ul sa dea PREADY");

  property p_apb_end;
    @(posedge clk_i) disable iff (!rst_ni)
    (psel && penable && pready) |=> !penable;
  endproperty
  assert_apb_end: assert property (p_apb_end) 
                  else $error("APB_ERR: Master-ul nu a coborat PENABLE dupa finalizarea tranzactiei (PREADY=1)");

  property p_valid_logs;
    @(posedge clk_i) disable iff (!rst_ni)
    valid_o |-> (logs_o !== 32'bx);
  endproperty
  assert_logs_valid: assert property (p_valid_logs) 
                     else $error("ERR: valid_o este activ, dar log-urile sunt necunoscute (X)");

endinterface
