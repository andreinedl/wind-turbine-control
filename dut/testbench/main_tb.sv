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

//localparam CLK_FREQ = 32'd100_000_000;
localparam CLK_FREQ = 32'd10;

wind_turbine_control #(
    .CLK_FREQ(CLK_FREQ)
	
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
    // --- Inițializare semnale APB ---
    start = 1'b0;
    pready = 1'b0;
end

// --- Stimuli APB: semnalul de start periodic ---
initial begin
    #100;  // Aștept după reset
    forever begin
        #5000;  // 5 microsecunde între fiecare start
        start = 1'b1;
        #10;
        start = 1'b0;
    end
end

// --- Stimuli APB: semnalul pready - sincronizat cu finalizarea tranzacției ---
initial begin
    pready = 1'b0;
    forever begin
		// Așteaptă intrarea în ACCESS pe front de ceas
		@(posedge clk iff (psel && penable));

		// Simulează 2 tacte de wait-state pe slave
		repeat (2) @(posedge clk);

		// Finalizează tranzacția pentru exact 1 tact
        pready = 1'b1;
        @(posedge clk);
        pready = 1'b0;

		// Așteaptă ieșirea din ACCESS înaintea următoarei tranzacții
		@(posedge clk iff (!psel || !penable));
    end
end

// --- Stimuli pentru senzori - Scenarii multiple ---
initial begin
    // --- 1. Inițializare ---
    wind_dir = 10'd0;
    yaw_angle = 10'd0;
	wind_speed = 10'd0;
    rpm_value = 9'd0;
    blade_angle = 8'd0;
	temp_value = 7'd10; // 25 grade C (Normal)
	
	#100;
	$display("\n========== SCENARIU 1: Vânt slab (fără mișcare) ==========");
	wind_speed = 10'd50;  // 5.0 m/s - sub limita minimă
	wind_dir = 10'd0;
	yaw_angle = 10'd0;
	rpm_value = 9'd0;
	blade_angle = 8'd0;
	temp_value = 7'd10;
	#500;
	
	$display("\n========== SCENARIU 2: Vânt normal - direcție 0° ==========");
	wind_speed = 10'd160; // 16.0 m/s - condiții normale
	wind_dir = 10'd0;
	yaw_angle = 10'd0;
	rpm_value = 9'd50;
	blade_angle = 8'd90;
	temp_value = 7'd10;
	#500;
	
	$display("\n========== SCENARIU 3: Vânt normal - rotație nacela la 45° ==========");
	wind_dir = 10'd450;  // Vântul se mută la 45 grade
	yaw_angle = 10'd450;  // Simulăm că motorul a adus nacela la 45 grade
	rpm_value = 9'd60;
	blade_angle = 8'd95;
	temp_value = 7'd10;
	#500;
	
	$display("\n========== SCENARIU 4: Vânt normal - rotație nacela la 90° ==========");
	wind_dir = 10'd900;   // 90 grade
	yaw_angle = 10'd900;  // Nacela la 90 grade
	rpm_value = 9'd65;
	blade_angle = 8'd100;
	temp_value = 7'd10;
	#500;
	
	$display("\n========== SCENARIU 5: Vânt puternic (turație crescută) ==========");
	wind_speed = 10'd300; // 30.0 m/s - vânt puternic
	wind_dir = 10'd450;
	yaw_angle = 10'd450;
	rpm_value = 9'd150;   // RPM mare
	blade_angle = 8'd140; // Pale mai orizontale (pitch up)
	temp_value = 7'd10;
	#500;
	
	$display("\n========== SCENARIU 6: Vânt foarte puternic (limitare RPM) ==========");
	wind_speed = 10'd400; // 40.0 m/s - vânt foarte puternic
	wind_dir = 10'd0;
	yaw_angle = 10'd0;
	rpm_value = 9'd250;   // RPM limitată
	blade_angle = 8'd160; // Pale aproape orizontale
	temp_value = 7'd10;
	#500;
	
	$display("\n========== SCENARIU 7: Schimbare rapidă de direcție vânt (180°) ==========");
	wind_speed = 10'd160;
	wind_dir = 10'd0;      // Vânt din Nord
	yaw_angle = 10'd0;
	rpm_value = 9'd60;
	blade_angle = 8'd90;
	temp_value = 7'd10;
	#300;
	
	yaw_angle = 10'd1000;  // Aproximat la limita pe 10 biți
	wind_dir = 10'd1000;
	rpm_value = 9'd65;
	blade_angle = 8'd95;
	#500;
	
	$display("\n========== SCENARIU 8: Temperatură ridicată (așteptare răcire) ==========");
	wind_speed = 10'd160;
	wind_dir = 10'd450;
	yaw_angle = 10'd450;
	rpm_value = 9'd80;
	blade_angle = 8'd85;
	temp_value = 7'd120; // limitat la domeniul pe 7 biți
	#500;
	
	$display("\n========== SCENARIU 9: Temperatură scăzută (încălzire) ==========");
	wind_speed = 10'd160;
	wind_dir = 10'd900;
	yaw_angle = 10'd900;
	rpm_value = 9'd60;
	blade_angle = 8'd100;
	temp_value = 7'd0;     // ~-25°C - Prea rece
	#500;
	
	$display("\n========== SCENARIU 10: Variație lentă a tuturor parametrilor ==========");
	for(int i = 0; i < 10; i++) begin
	    wind_speed = 10'd100 + (i * 10);
	    wind_dir = i * 10'd100;  // 0..900, fără overflow pe 10 biți
	    yaw_angle = i * 10'd100;
	    rpm_value = 9'd30 + (i * 10);
	    blade_angle = 8'd50 + (i * 5);
	    temp_value = 7'd50 + (i * 5);
	    #200;
	end
	
	$display("\n========== SCENARIU 11: Condiții normale finale ==========");
	wind_speed = 10'd160;
	wind_dir = 10'd450;
	yaw_angle = 10'd450;
	rpm_value = 9'd65;
	blade_angle = 8'd95;
	temp_value = 7'd10;
	#1000;
	
	$display("\n========== FIN SIMULARE ==========");
	#100;
	//$stop;
end

// --- Monitor pentru a vedea datele trimise prin APB ---
initial begin
    $monitor("Time=%0t | APB: start=%b pready=%b psel=%b penable=%b | pwdata=0x%08h | Senzori: WSpeed=%0d WDir=%0d YawAng=%0d RPM=%0d BladeAng=%0d Temp=%0d | Out: YawPos=%0d BladePos=%0d Heat=%b EMBrake=%b Err=0x%h",
        $time, start, pready, psel, penable, pwdata,
        wind_speed, wind_dir, yaw_angle, rpm_value, blade_angle, temp_value,
        yaw_pos, blade_pos, heat, em_brake, error_feedback);
end
endmodule   