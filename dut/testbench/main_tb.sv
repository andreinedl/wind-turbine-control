`timescale 1ns/1ps

module wind_turbine_control_tb();
reg clk;
reg rst_n;

//Intrari (senzori)
reg [9:0] wind_speed;
reg [9:0] wind_dir;
reg [9:0] yaw_angle;
reg [8:0] rpm_value;
reg [7:0] blade_angle;
reg [6:0] temp_value;

// Output-uri de la DUT

wire [9:0] yaw_pos;
wire [7:0] blade_pos;
wire heat;
wire em_brake;

wire [3:0] error_feedback;

wire paddr;
wire pwrite;
wire [31:0] pwdata;
wire psel;
wire penable;

// INPUT APB
reg start;
reg pready;

wind_turbine_control #(
    .CLK_FREQ(32'd100_000_000)
	
	/*.ONE_MINUTE_TICKS(CLK_FREQ * 60),
	.THIRTY_SEC_TICKS(CLK_FREQ * 30),
	.FIVE_MIN_TICKS(CLK_FREQ * 300)*/
) wind_turbine_inst (
    .clk_i(clk),
    .rst_ni(rst_n),

    // Interfața Senzori (Intrări)
    .wind_speed_i(wind_speed),       // 0-60.0 m/s
    .wind_dir_i(wind_dir),  		// 0-359 deg (pentru nacelă)
    .yaw_angle_i(yaw_angle),      	// Poziția actuală a nacelei
    .rpm_value_i(rpm_value),        // 0-35.0 RPM
    .blade_angle_i(blade_angle),    	// Unghiul actual al palelor
    .temp_value_i(temp_value),       // Temperatura internă

    // Interfața Actuatoare (Ieșiri)
    .yaw_pos_o(yaw_pos),      	// Comandă pentru nacelă				
    .blade_pos_o(blade_pos),    	// Comandă pentru pale
    .heat_o(heat),       		// Comandă rezistență
    .em_brake_o(em_brake), 		// Frână mecanică
    
    // Status Sistem
    .error_feedback(error_feedback),    //0001-em. break   0010-yaw error   0100-blade error   1000-temperature error
	
	//Interfata APB (control)
	.start_i(start),						//trigger pentru a incepe rafala de 3 tranzactii (asta o sa fie un semnal periodic care zice cand se trimit datele)
	.pready_i(pready),
	
	.paddr_o(paddr),						//paddr 1 bit in cazul nostru (trimitem la aceeasi adresa mereu,
	.pwrite_o(pwrite),						//ar fi useless sa fie o adresa de 32 biti)
	.pwdata_o(pwdata),
	.psel_o(psel),
	.penable_o(penable)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    rst_n = 1;
    rst_n = 0;
    repeat (2) @(posedge clk)
    rst_n = 1;
end

initial begin
    // --- 1. Inițializare ---
    wind_dir = 10'd0;
    yaw_angle = 10'd0;
	wind_speed = 10'd0;
    rpm_value = 9'd0;
    blade_angle = 8'd0;
	temp_value = 7'd50; // 25 grade C (Normal)
	
	#20;

	wind_speed = 10'd160; // 16.0 m/s -> Ar trebui să rezulte un unghi > 0
	wind_dir = 10'd45; // Vântul se mută la 45 grade
	yaw_angle = 10'd45;  // Simulăm că motorul a adus nacela la 45 grade
	temp_value = 7'd25;  // 0 grade C

    #20;
	
	#50;
    yaw_angle = 10'd45;  // Simulăm că motorul a adus nacela la 45 grade
	blade_angle = 8'd180; 
	temp_value = 7'd45;
	wind_dir = 10'd90; // Vântul se mută la 90 grade
	#100;
	
end
endmodule   