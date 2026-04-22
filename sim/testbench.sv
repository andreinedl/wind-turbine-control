//-------------------------------------------------------------------------
//				www.verificationguide.com   testbench.sv
//-------------------------------------------------------------------------
//tbench_top or testbench top, this is the top most file, in which DUT(Design Under Test) and Verification environment are connected. 
//-------------------------------------------------------------------------

//Includere interfete
`include "../interfaces/input_interface.sv"
`include "../interfaces/output_interface.sv"
`include "../interfaces/server_interface.sv"

`include "environment.sv"

//-------------------------[TESTE]---------------------------------
//`include "test1.sv"
//----------------------------------------------------------------

module testbench;
  
//clock & reset
bit clk;
bit reset;

//clock generation
always #5 clk = ~clk;

//reset generation
initial begin
  reset = 0;
  #15 reset =1;
end

//creatinng instance of interface, in order to connect DUT and testcase
input_interface   input_intf (.clk_i(clk), .rst_ni(reset));
output_interface  output_intf(.clk_i(clk), .rst_ni(reset));
server_interface  server_intf(.clk_i(clk), .rst_ni(reset));

wind_turbine_control #(
    .CLK_FREQ(32'd50_000_000) // 50 MHz
) DUT (
    .clk_i(clk),
    .rst_ni(reset),

    .wind_speed_i  (input_intf.wind_speed_i),
    .wind_dir_i    (input_intf.wind_dir_i),
    .yaw_angle_i   (input_intf.yaw_angle_i),
    .rpm_value_i   (input_intf.rpm_value_i),
    .blade_angle_i (input_intf.blade_angle_i),
    .temp_value_i  (input_intf.temp_value_i),

    .yaw_pos_o        (output_intf.yaw_pos_o),
    .blade_pos_o      (output_intf.blade_pos_o),
    .heat_o           (output_intf.heat_o),
    .em_brake_o       (output_intf.em_brake_o),
    .error_feedback_o (output_intf.error_feedback_o),

    .start_i   (start_i),
    .pready_i  (server_intf.pready),
    .paddr_o   (server_intf.paddr),
    .pwrite_o  (server_intf.pwrite),
    .pwdata_o  (server_intf.pwdata),
    .psel_o    (server_intf.psel),
    .penable_o (server_intf.penable)
);

//enabling the wave dump
initial begin 
  $dumpfile("dump.vcd"); 
  $dumpvars(0, testbench);
end

endmodule