module wind_turbine_control #(
    parameter CLK_FREQ = 32'd50_000_000 // 50 MHz
)

(
    input  logic        clk_i,
    input  logic        rst_ni,

    // Interfața Senzori (Intrări)
    input  logic [9:0]  wind_speed_i,       // 0-60.0 m/s
    input  logic [9:0]  wind_dir_i,  		// 0-359 deg (pentru nacelă) (precizie 0,5 grade)
    input  logic [9:0]  yaw_angle_i,      	// Poziția actuală a nacelei
    input  logic [8:0]  rpm_value_i,        // 0-35.0 RPM
    input  logic [7:0]  blade_angle_i,    	// Unghiul actual al palelor
    input  logic [6:0]  temp_value_i,       // Temperatura internă

    // Interfața Actuatoare (Ieșiri)
    output logic [9:0]  yaw_pos_o,      	// Comandă pentru nacelă				
    output logic [7:0]  blade_pos_o,    	// Comandă pentru pale
    output logic        heat_o,       		// Comandă rezistență
    output logic        em_brake_o, 		// Frână mecanică
    
    // Status Sistem
    output logic [3:0]  error_feedback_o,    //0001-em. break   0010-yaw error   0100-blade error   1000-temperature error
	
	//Interfata APB (control)
	input logic 		start_i,						//trigger pentru a incepe rafala de 3 tranzactii (asta o sa fie un semnal periodic care zice cand se trimit datele)
	input logic 		pready_i,
	
	output logic 		paddr_o,						//paddr 1 bit in cazul nostru (trimitem la aceeasi adresa mereu,
	output logic 		pwrite_o,						//ar fi useless sa fie o adresa de 32 biti)
	output logic [31:0] pwdata_o,
	output logic 		psel_o,
	output logic		penable_o
);

assign em_brake_o = error_feedback_o[0];
	
// --- 1. Instanțiere Control Nacelă (Yaw) ---
yaw_angle_control #(
    .ONE_MINUTE_TICKS(CLK_FREQ * 60)	// 60 sec la 50MHz
) yaw_ctrl (
    .clk_i(clk_i),								       
    .rst_ni(rst_ni),                                 
    .wind_dir_i(wind_dir_i),              
    .yaw_angle_i(yaw_angle_i),                 
    .yaw_pos_o(yaw_pos_o),          
    .error(error_feedback_o[1])                     
);
// --- 2. Instanțiere Control Pale (Pitch) ---
blade_pitch_control #(
    .THIRTY_SEC_TICKS(CLK_FREQ * 30)	// 30 sec la 50MHz
) pitch_ctrl (
    .clk_i(clk_i),										
    .rst_ni(rst_ni),                                      
    .wind_speed_i(wind_speed_i),                        
    .rpm_value_i(rpm_value_i),                          
    .blade_angle_i(blade_angle_i),                      
    .blade_pos_o(blade_pos_o),                  
    .error(error_feedback_o[2]),                          
    .em_break_o(error_feedback_o[0])                        
);                                                      
// --- 3. Instanțiere Control Încălzire (Heater) ---
heater_control #(
    .FIVE_MIN_TICKS(CLK_FREQ * 300)		// 5 min la 50MHz
) heat_ctrl (
    .clk_i(clk_i),						
    .rst_ni(rst_ni),
    .temp_value_i(temp_value_i),
    .heat_o(heat_o),
    .error(error_feedback_o[3])
);

logic [95:0] info_i = {error_feedback_o, wind_speed_i, wind_dir_i, yaw_angle_i, rpm_value_i, blade_angle_i, temp_value_i, yaw_pos_o, blade_pos_o, heat_o, em_brake_o};

apb_master apb_master_tb(
	.clk_i(clk_i),
	.rst_ni(rst_ni),
	.start_i(start_i),						
	.pready_i(pready_i),
	.info_i(info_i),
	
	.paddr_o(paddr_o),						
	.pwrite_o(pwrite_o),						
	.pwdata_o(pwdata_o),
	.psel_o(psel_o),
	.penable_o(penable_o)
);

endmodule