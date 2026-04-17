module wind_turbine_control_tb();

    input  logic        clk_i;
    input  logic        rst_ni;

    // Interfața Senzori (Intrări)
    input  logic [9:0]  wind_speed_i;       // 0-60.0 m/s
    input  logic [9:0]  wind_dir_i;  		// 0-359 deg (pentru nacelă)
    input  logic [9:0]  yaw_angle_i;     	// Poziția actuală a nacelei
    input  logic [8:0]  rpm_value_i;        // 0-35.0 RPM
    input  logic [7:0]  blade_angle_i;    	// Unghiul actual al palelor
    input  logic [6:0]  temp_value_i;       // Temperatura internă

    // Interfața Actuatoare (Ieșiri)
    output logic [9:0]  yaw_pos_o;      	// Comandă pentru nacelă				
    output logic [7:0]  blade_pos_o;    	// Comandă pentru pale
    output logic        heat_o;       		// Comandă rezistență
    output logic        em_brake_o; 		// Frână mecanică
    
    // Status Sistem
    output logic [3:0]  error_feedback;    //0001-em. break   0010-yaw error   0100-blade error   1000-temperature error
	

wind_turbine_control_tb #(
    .CLK_FREQ = 32'd50_000_000 // 50 MHz
	
	.ONE_MINUTE_TICKS(CLK_FREQ * 60)
	.THIRTY_SEC_TICKS(CLK_FREQ * 30)
	.FIVE_MIN_TICKS(CLK_FREQ * 300)
)
main_tb
(
    .clk_i(clk_i),
    .rst_ni(rst_ni),

    // Interfața Senzori (Intrări)
    .wind_speed_i(wind_speed_i),       // 0-60.0 m/s
    .wind_dir_i(wind_dir_i),  		// 0-359 deg (pentru nacelă)
    .yaw_angle_i(yaw_angle_i),      	// Poziția actuală a nacelei
    .rpm_value_i(rpm_value_i),        // 0-35.0 RPM
    .blade_angle_i(blade_angle_i),    	// Unghiul actual al palelor
    .temp_value_i(temp_value_i),       // Temperatura internă

    // Interfața Actuatoare (Ieșiri)
    .yaw_pos_o(yaw_pos_o),      	// Comandă pentru nacelă				
    .blade_pos_o(blade_pos_o),    	// Comandă pentru pale
    .heat_o(heat_o),       		// Comandă rezistență
    .em_brake_o(em_brake_o), 		// Frână mecanică
    
    // Status Sistem
    .error_feedback(error_feedback),    //0001-em. break   0010-yaw error   0100-blade error   1000-temperature error
	
	//Interfata APB (control)
	.start_i(start_i),						//trigger pentru a incepe rafala de 3 tranzactii (asta o sa fie un semnal periodic care zice cand se trimit datele)
	.pready_i(pready_i),
	
	.paddr_o(paddr_o),						//paddr 1 bit in cazul nostru (trimitem la aceeasi adresa mereu,
	.pwrite_o(pwrite_o),						//ar fi useless sa fie o adresa de 32 biti)
	.pwdata_o(pwdata_o),
	.psel_o(psel_o),
	.penable_o(penable_o)
);

always #5 clk = ~clk;

    initial begin
        // --- 1. Inițializare ---
        clk_i = 0;
        rst_ni = 0;
        wind_angle_i = 10'd0;
        yaw_angle_i = 10'd0;
		wind_speed_i = 10'd0;
        rpm_value_i = 9'd0;
        blade_angle_i = 8'd0;
		temp_value_i = 7'd50; // 25 grade C (Normal)
		
		#20 rst_ni = 1;
		#20;
	
		wind_speed_i = 10'd160; // 16.0 m/s -> Ar trebui să rezulte un unghi > 0
		wind_angle_i = 10'd45; // Vântul se mută la 45 grade
		yaw_angle_i = 10'd45;  // Simulăm că motorul a adus nacela la 45 grade
		temp_value_i = 7'd25;  // 0 grade C
        #20;
		
		#50;
        yaw_angle_i = 10'd45;  // Simulăm că motorul a adus nacela la 45 grade
		blade_angle_i = 8d'180; 
		temp_value_i = 7'd45;
		wind_angle_i = 10'd90; // Vântul se mută la 90 grade
		#100;
		
	end
	endmodule