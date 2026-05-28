`timescale 1ns/1ps

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
`include "../tests/em_brake_test.sv"
`include "../tests/simple_test.sv"
`include "../tests/random_test.sv"
`include "../tests/limit_test.sv"
`include "../tests/low_temp_test.sv"
`include "../tests/rst_test.sv"
//----------------------------------------------------------------

module testbench;
  
//clock & reset
bit clk;
bit reset;
bit start_i;

//clock generation
always #5 clk = ~clk;

//reset generation
initial begin
  reset = 0;
  #15 reset =1;

  forever begin
    @(input_intf.reset_assert); // se asteapta activarea reset-ului
    $display("[Testbench] Reset asserted at %0t", $time);
    reset = 0;

    @(input_intf.reset_deassert); // se asteapta dezactivarea reset-ului
    $display("[Testbench] Reset deasserted at %0t", $time);
    reset = 1;
  end
end

//creating instance of interface, in order to connect DUT and testcase
input_interface   input_intf (.clk_i(clk), .rst_ni(reset));
output_interface  output_intf(.clk_i(clk), .rst_ni(reset));
server_interface  server_intf(.clk_i(clk), .rst_ni(reset));

//instantiere teste
// em_brake_test 	em_brake_test(input_intf, output_intf, server_intf);
// simple_test 	simple_test(input_intf, output_intf, server_intf);
random_test		random_test(input_intf, output_intf, server_intf);
// limit_test 		limit_test(input_intf, output_intf, server_intf);
// low_temp_test	low_temp_test(input_intf, output_intf, server_intf);
// rst_test		rst_test(input_intf, output_intf, server_intf);

wind_turbine_control #(
    .CLK_PERIOD_NS(20),
    .NS_PER_SEC(2)
) DUT (
    .clk_i(clk),
    .rst_ni(reset),
//intrari
    .wind_speed_i  (input_intf.wind_speed_i),
    .wind_dir_i    (input_intf.wind_dir_i),
    .yaw_angle_i   (input_intf.yaw_angle_i),
    .rpm_value_i   (input_intf.rpm_value_i),
    .blade_angle_i (input_intf.blade_angle_i),
    .temp_value_i  (input_intf.temp_value_i),
//iesiri
    .yaw_pos_o        (output_intf.yaw_pos_o),
    .blade_pos_o      (output_intf.blade_pos_o),
    .heat_o           (output_intf.heat_o),
    .em_brake_o       (output_intf.em_brake_o),
    .error_feedback_o (output_intf.error_feedback_o),
//APB
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