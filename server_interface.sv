interface server_interface(input logic clk_i, rst_ni);
  // Semnale Server
  logic [31:0] logs_o;       // 32 biți, biți împărțiți
  logic        valid_o;      // 1 bit: valid server logs
  logic [31:0] paddr;   
  logic        psel;    
  logic        penable; 
  logic        pwrite;  
  logic [31:0] pwdata;  
  logic [31:0] prdata;  
  logic        pready;  
  logic        pslverr; 

  clocking driver_cb @(posedge clk_i);
    default input #1 output #1;
    // Semnale conduse de Driver
    output paddr, psel, penable, pwrite, pwdata;
    // Semnale citite de Driver de la DUT (Turbina)
    input  prdata, pready, pslverr, logs_o, valid_o; 
  endclocking

  clocking monitor_cb @(posedge clk_i);
    default input #1 output #1;
    input paddr, psel, penable, pwrite, pwdata;
    input prdata, pready, pslverr, logs_o, valid_o;
  endclocking

  modport DRIVER  (clocking driver_cb, input clk_i, rst_ni);
  modport MONITOR (clocking monitor_cb, input clk_i, rst_ni);
  modport DUT     (input paddr, psel, penable, pwrite, pwdata,
                   output prdata, pready, pslverr, logs_o, valid_o, 
                   input clk_i, rst_ni);

  property p_apb_penable_setup;
    @(posedge clk_i) disable iff (!rst_ni)
    psel && !penable |=> penable;
  endproperty
  assert_apb_penable: assert property (p_apb_penable_setup) 
                      else $error("APB_ERR: PENABLE trebuie sa urmeze dupa PSEL la 1 ciclu distanta");

  property p_apb_addr_stable;
    @(posedge clk_i) disable iff (!rst_ni)
    psel |-> $stable(paddr);
  endproperty
  assert_apb_addr_stable: assert property (p_apb_addr_stable) 
                          else $error("APB_ERR: PADDR s-a schimbat in timp ce PSEL este activ");

  property p_apb_psel_hold;
    @(posedge clk_i) disable iff (!rst_ni)
    (psel && penable && !pready) |=> (psel && penable);
  endproperty
  assert_apb_hold: assert property (p_apb_psel_hold) 
                   else $error("APB_ERR: PSEL/PENABLE au scazut inainte de PREADY");

  property p_apb_end;
    @(posedge clk_i) disable iff (!rst_ni)
    (psel && penable && pready) |=> !penable;
  endproperty
  assert_apb_end: assert property (p_apb_end) 
                  else $error("APB_ERR: PENABLE nu a scazut dupa PREADY");

  property p_valid_logs;
    @(posedge clk_i) disable iff (!rst_ni)
    valid_o |-> (logs_o !== 32'bx);
  endproperty
  assert_logs_valid: assert property (p_valid_logs) 
                     else $error("ERR: valid_o este activ, dar log-urile sunt necunoscute (X)");

endinterface