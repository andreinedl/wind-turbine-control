module wind_turbine_control #(
    parameter CLK_PERIOD_NS = 20
) (
    input        clk_i,
    input        rst_ni,

    // Interfața Senzori (Intrări)
    input [9:0]  wind_speed_i,      // 0-60.0 m/s
    input [9:0]  wind_dir_i,  		// 0-359 deg (pentru nacelă) (precizie 0,5 grade)
    input [9:0]  yaw_angle_i,      	// Poziția actuală a nacelei
    input [8:0]  rpm_value_i,       // 0-35.0 RPM
    input [7:0]  blade_angle_i,    	// Unghiul actual al palelor
    input [6:0]  temp_value_i,      // Temperatura internă

    // Interfața Actuatoare (Ieșiri)
    output logic [9:0]  yaw_pos_o,      	// Comandă pentru nacelă				
    output logic [7:0]  blade_pos_o,    	// Comandă pentru pale
    output logic        heat_o,       		// Comandă rezistență
    output logic        em_brake_o, 		// Frână mecanică
    
    // Status Sistem
    output logic [3:0]  error_feedback_o,    //0001-em. break   0010-yaw error   0100-blade error   1000-temperature error
	
	//Interfata APB (control)
	input        		pready_i,
	output logic 		paddr_o,						
	output logic 		pwrite_o,						
	output logic [31:0] pwdata_o,
	output logic 		psel_o,
	output logic		penable_o
);

localparam NS_PER_SEC = 1_000_000_000;
localparam YAW_COUNTER_SEC = 60;
localparam HEAT_COUNTER_SEC = 300;
localparam BLADE_COUNTER_SEC = 30;

assign em_brake_o = error_feedback_o[0];

logic [95:0] info;
logic [95:0] info_d;
logic info_change;

assign info = {error_feedback_o, wind_speed_i, wind_dir_i, yaw_angle_i, rpm_value_i, blade_angle_i, temp_value_i, yaw_pos_o, blade_pos_o, heat_o, em_brake_o};
assign info_change = (info_d != info);

always_ff @(posedge clk_i or negedge rst_ni) begin
    if(!rst_ni) info_d <= '0; else
                info_d <= info;
end
	
// Modul nacela
yaw_angle_control #(
    .YAW_ERR_CNT_TSH((NS_PER_SEC * YAW_COUNTER_SEC) / CLK_PERIOD_NS)
) yaw_ctrl (
    .clk_i(clk_i),								       
    .rst_ni(rst_ni),                                 
    .wind_dir_i(wind_dir_i),              
    .yaw_angle_i(yaw_angle_i),                 
    .yaw_pos_o(yaw_pos_o),          
    .error_o(error_feedback_o[1])                     
);

// Modul pale
blade_pitch_control #(
    .BLADE_ERR_CNT_TSH((NS_PER_SEC * BLADE_COUNTER_SEC) / CLK_PERIOD_NS)
) pitch_ctrl (
    .clk_i(clk_i),										
    .rst_ni(rst_ni),                                      
    .wind_speed_i(wind_speed_i),                        
    .rpm_value_i(rpm_value_i),                          
    .blade_angle_i(blade_angle_i),                      
    .blade_pos_o(blade_pos_o),                  
    .error_o(error_feedback_o[2]),                          
    .em_break_o(error_feedback_o[0])                        
);          

// Modul incalzire auxiliara
heater_control #(
    .HEAT_ERR_CNT_TSH((NS_PER_SEC * HEAT_COUNTER_SEC) / CLK_PERIOD_NS)
) heat_ctrl (
    .clk_i(clk_i),						
    .rst_ni(rst_ni),
    .temp_value_i(temp_value_i),
    .heat_o(heat_o),
    .error_o(error_feedback_o[3])
);

apb_master apb_ctrl(
	.clk_i(clk_i),
	.rst_ni(rst_ni),
	.pready_i(pready_i),
	.info_i(info),
	.start_i(info_change),
	.paddr_o(paddr_o),						
	.pwrite_o(pwrite_o),						
	.pwdata_o(pwdata_o),
	.psel_o(psel_o),
	.penable_o(penable_o)
);

endmodule