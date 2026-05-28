interface input_interface(input logic clk_i, rst_ni);

  event reset_assert;  // Reset-ul a fost activat
  event reset_deassert;   // Simularea poate continua normal

  // Semnale Senzori
  logic [9:0]  wind_dir_i;     // direcția vântului, 10 biți: 0-720 (0-360.0 grade)
  logic [9:0]  wind_speed_i;   // viteza vântului, 10 biți: 0-600 (0-60 m/s)
  logic [6:0]  temp_value_i;   // temperatura ambiantă, 7 biți: 0=-25C la 100=75C
  logic [8:0]  rpm_value_i;    // turația rotorului, 9 biți: 0-350 (0-35 RPM)
  logic [7:0]  blade_angle_i;  // unghiul palelor, 8 biți: 0-180 (0-90 grade)
  logic [9:0]  yaw_angle_i;    // orientarea nacelei, 10 biți: 0-720 (0-360 grade)

  // Clocking block folosit de driver ca sa scrie semnalele sincronizat cu ceasul.
  clocking driver_cb @(posedge clk_i);
    default input #1 output #1; // input #1 face ca inputul sa fie citit cu o unitate de timp mai devreme
                                // output #1 face ca output ul sa fie scris cu o unitate de timp mai tarziu
    output wind_dir_i, wind_speed_i, temp_value_i, rpm_value_i;
    output blade_angle_i, yaw_angle_i;
  endclocking

  // Clocking block pasiv pentru monitorizare.
  // Monitorul foloseste acest bloc doar ca sa citeasca semnalele dupa ce s-au stabilizat,
  // fara sa le poata modifica.
  clocking monitor_cb @(posedge clk_i);
    default input #1 output #1; // input #1 face ca inputul sa fie citit cu o unitate de timp mai devreme
                                // output #1 face ca output ul sa fie scris cu o unitate de timp mai tarziu
    input wind_dir_i, wind_speed_i, temp_value_i, rpm_value_i;
    input blade_angle_i, yaw_angle_i;
  endclocking

  // modport-ul selecteaza porturile vizibile si directia lor
  modport DRIVER  (clocking driver_cb, input clk_i, rst_ni);

  // Modport-ul monitorului este read-only: poate observa `monitor_cb`, dar nu poate conduce semnale.
  modport MONITOR (clocking monitor_cb, input clk_i, rst_ni);
  
endinterface