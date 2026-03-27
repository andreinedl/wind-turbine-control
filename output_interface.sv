interface output_interface(input logic clk_i, rst_ni);
  // Semnale Comenzi
  logic [7:0]  blade_pos_o;  // 8 biți: orientare pale
  logic [9:0]  yaw_pos_o;    // 10 biți: orientare nacelă
  logic        heat_o;       // 1 bit: on/off încălzire
  logic        em_brake_o;   // 1 bit: on/off frână urgență

  clocking monitor_cb @(posedge clk_i);
    default input #1 output #1;
    input blade_pos_o, yaw_pos_o, heat_o, em_brake_o;
  endclocking

  modport MONITOR (clocking monitor_cb, input clk_i, rst_ni);

  property p_blade_out_range;
    @(posedge clk_i) disable iff (!rst_ni) blade_pos_o <= 8'd180;
  endproperty
  assert_blade_out: assert property (p_blade_out_range) 
                    else $error("ERR: Iesirea blade_pos_o > 180");
					
  // Cover pentru a asigura că am testat valorile macar o data 
  COVER_BLADE_C: cover property (p_blade_out_range);

  property p_yaw_out_range;
    @(posedge clk_i) disable iff (!rst_ni) yaw_pos_o <= 10'd720;
  endproperty
  assert_yaw_out: assert property (p_yaw_out_range)
                  else $error("ERR: Iesirea yaw_pos_o > 720");
	
  // Cover pentru a asigura că am testat valorile macar o data   
  COVER_YAW_C: cover property (p_yaw_out_range);

  property p_safety_heat_brake;
    @(posedge clk_i) disable iff (!rst_ni) em_brake_o |-> !heat_o;
  endproperty
  assert_safety: assert property (p_safety_heat_brake) 
                 else $warning("AVERTIZARE: Incalzirea este activa in timpul franei de urgenta!");
				 
  // Cover pentru a asigura că am testat valorile macar o data  
  COVER_SAFETY_C: cover property (p_safety_heat_brake);

endinterface
