interface output_interface(input logic clk_i, rst_ni);
  // Semnale Comenzi emise de DUT 
  logic [7:0]  blade_pos_o;       // 8 biți: Comandă orientare unghi pale (0-180)
  logic [9:0]  yaw_pos_o;         // 10 biți: Comandă orientare nacelă (0-720)
  logic        heat_o;            // 1 bit: Comandă activare/dezactivare încălzire
  logic        em_brake_o;        // 1 bit: Comandă activare frână de urgență
  logic [3:0]  error_feedback_o;  // 4 biți: Coduri eroare (rotație, nacelă, încălzire)

  // Clocking Block pentru monitorizarea ieșirilor
  clocking monitor_cb @(posedge clk_i);
    default input #1 output #1;
    input blade_pos_o, yaw_pos_o, heat_o, em_brake_o, error_feedback_o;
  endclocking

  // Modport pentru Monitor: permite observarea semnalelor sincronizate cu ceasul
  modport MONITOR (clocking monitor_cb, input clk_i, rst_ni);

  // Verificarea limitei superioare pentru comanda poziției palelor
  property p_blade_out_range;
    @(posedge clk_i) disable iff (!rst_ni) blade_pos_o <= 8'd180;
  endproperty
  assert_blade_out: assert property (p_blade_out_range) 
                    else $error("ERR: Iesirea blade_pos_o depaseste limita maxima (180)");
  // Asigurăm acoperirea funcțională: cel puțin o comandă validă a fost observată
  COVER_BLADE_C: cover property (p_blade_out_range);

  // Verificarea limitei superioare pentru comanda poziției nacelei
  property p_yaw_out_range;
    @(posedge clk_i) disable iff (!rst_ni) yaw_pos_o <= 10'd720;
  endproperty
  assert_yaw_out: assert property (p_yaw_out_range)
                  else $error("ERR: Iesirea yaw_pos_o depaseste limita maxima (720)");
  // Asigurăm acoperirea funcțională pentru mișcarea nacelei
  COVER_YAW_C: cover property (p_yaw_out_range);

  // Verificarea corelației dintre frâna de urgență și bitul de eroare MSB
  // MSB-ul semnalului error_feedback (bitul 3) trebuie să reflecte starea frânei de urgență
  property p_safety_heat_brake;
    @(posedge clk_i) disable iff (!rst_ni) em_brake_o == error_feedback_o[3];
  endproperty
  assert_safety: assert property (p_safety_heat_brake) 
                 else $warning("AVERTIZARE: Inconsistenta intre em_brake_o si statusul error_feedback[3]!");
  // Verificăm dacă scenariul de siguranță a fost exercitat în simulare
  COVER_SAFETY_C: cover property (p_safety_heat_brake);

endinterface