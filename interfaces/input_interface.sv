interface input_interface(input logic clk_i, rst_ni);
  // Semnale Senzori
  logic [9:0]  wind_dir_i;     // 10 biți: 0-720 (0-360.0 grade)
  logic [9:0]  wind_speed_i;   // 10 biți: 0-600 (0-60 m/s)
  logic [6:0]  temp_value_i;   // 7 biți: 0=-25C la 100=75C
  logic [8:0]  rpm_value_i;    // 9 biți: 0-350 (0-35 RPM)
  logic [7:0]  blade_angle_i;  // 8 biți: 0-180 (0-90 grade)
  logic [9:0]  yaw_angle_i;    // 10 biți: 0-720 (0-360 grade)

  // Clocking Block pentru Conducerea semnalelor 
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
  
endinterface