interface input_interface(input logic clk_i, rst_ni);
  // Semnale Senzori
  logic [11:0] wind_dir_i;     // 12 biți: 0-3600 (0-360.0 grade)
  logic [9:0]  wind_speed_i;   // 10 biți: 0-600 (0-60 m/s)
  logic [6:0]  temp_value_i;   // 7 biți: 0=-25C la 100=75C
  logic [8:0]  rpm_value_i;    // 9 biți: 0-350 (0-35 RPM)
  logic [7:0]  blade_angle_i;  // 8 biți: 0-180 (0-90 grade)
  logic [9:0]  yaw_angle_i;    // 10 biți: 0-720 (0-360 grade)

  // Clocking Block pentru Monitorizare
  clocking driver_cb @(posedge clk_i);
    default input #1 output #1;
    output wind_dir_i, wind_speed_i, temp_value_i, rpm_value_i;
    output blade_angle_i, yaw_angle_i;
  endclocking

  // Clocking Block pentru Monitorizare
  clocking monitor_cb @(posedge clk_i);
    default input #1 output #1;
    input wind_dir_i, wind_speed_i, temp_value_i, rpm_value_i;
    input blade_angle_i, yaw_angle_i;
  endclocking

  modport DRIVER  (clocking driver_cb, input clk_i, rst_ni);
  modport MONITOR (clocking monitor_cb, input clk_i, rst_ni);

  property p_wind_dir_range;
    @(posedge clk_i) disable iff (!rst_ni) wind_dir_i <= 12'd3600;
  endproperty
  assert_wind_dir: assert property (p_wind_dir_range) 
                   else $error("ERR: wind_dir_i in afara intervalului (0-3600)");
	
  // Cover pentru a asigura că am testat valorile macar o data 
  COVER_WIND_C: cover property (p_wind_dir_range);

  property p_wind_speed_range;
    @(posedge clk_i) disable iff (!rst_ni) wind_speed_i <= 10'd600;
  endproperty
  assert_wind_speed: assert property (p_wind_speed_range) 
                     else $error("ERR: wind_speed_i in afara intervalului (0-600)");
					 
  // Cover pentru a asigura că am testat valorile macar o data  
  COVER_WIND_S_C: cover property (p_wind_speed_range);

  property p_temp_range;
    @(posedge clk_i) disable iff (!rst_ni) temp_value_i <= 7'd100;
  endproperty
  assert_temp: assert property (p_temp_range) 
               else $error("ERR: temp_value_i in afara intervalului (0-100)");
			   
  // Cover pentru a asigura că am testat valorile macar o data 
  COVER_TEMP_C: cover property (p_temp_range);

  property p_rpm_range;
    @(posedge clk_i) disable iff (!rst_ni) rpm_value_i <= 9'd350;
  endproperty
  assert_rpm: assert property (p_rpm_range) 
              else $error("ERR: rpm_value_i in afara intervalului (0-350)");
			  
  // Cover pentru a asigura că am testat valorile macar o data 
  COVER_RPM_C: cover property (p_rpm_range);

  property p_blade_angle_range;
    @(posedge clk_i) disable iff (!rst_ni) blade_angle_i <= 8'd180;
  endproperty
  assert_blade_angle: assert property (p_blade_angle_range) 
                      else $error("ERR: blade_angle_i in afara intervalului (0-180)");
					  
  // Cover pentru a asigura că am testat valorile macar o data   
  COVER_BLADE_C: cover property (p_blade_angle_range);

  property p_yaw_angle_range;
    @(posedge clk_i) disable iff (!rst_ni) yaw_angle_i <= 10'd720;
  endproperty
  assert_yaw_angle: assert property (p_yaw_angle_range) 
                    else $error("ERR: yaw_angle_i in afara intervalului (0-720)");
					
  // Cover pentru a asigura că am testat valorile macar o data   
  COVER_YAW_C: cover property (p_yaw_angle_range);

endinterface
