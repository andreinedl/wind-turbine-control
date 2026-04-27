module blade_pitch_control #(
    parameter BLADE_ERR_CNT_TSH 	= 500,
	parameter MAX_RPM				= 350,
	parameter MAX_WIND				= 250,
	parameter ANGLE_INCREASE_TSH	= 120
)
(
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic [9:0]  wind_speed_i,         // 0-600 (0-60.0 m/s)
    input  logic [8:0]  rpm_value_i,          // 0-350 (0-35.0 RPM)
    input  logic [7:0]  blade_angle_i,        // Unghi actual 0-180 (0-90.0 deg)
    
    output logic [7:0]  blade_pos_o, 		  // Unghi tinta 0-180
    output logic        error_o,              // Eroare timeout 30s
    output logic        em_break_o            // Frana de urgenta (RPM > 350)
);

logic [31:0] timer;
logic        is_moving;

assign em_break_o = (rpm_value_i >= MAX_RPM);			// Se activează daca RPM atinge sau depaseste pragul de 350 (35.0 RPM)

always_comb begin
    if (em_break_o || (wind_speed_i > MAX_WIND))	blade_pos_o = 8'd180; else	// Daca e frana de urgenta sau vant peste valoare maxima permisa, unghiul merge la 90 grade (valoare 180)
    if (wind_speed_i > ANGLE_INCREASE_TSH)			blade_pos_o = (wind_speed_i - ANGLE_INCREASE_TSH) >> 1; else // Logica proportionala simpla: pe masura ce vantul creste peste 12m/s (120), 
													blade_pos_o = 8'd0;											// crestem unghiul pentru a limita puterea captata
end

assign is_moving = (blade_pos_o != blade_angle_i);		// Verificam daca unghiul actual este diferit de cel dorit

always_ff @(posedge clk_i or negedge rst_ni) begin		// Procesul de numarare si generare eroare (Timeout 30 secunde)
	if(~rst_ni)							timer <= 32'd0;			else
	if(is_moving)	begin
		if(timer < BLADE_ERR_CNT_TSH)	timer <= timer + 1; end else
										timer <= 32'd0;
end

always_ff @(posedge clk_i or negedge rst_ni) begin
	if(~rst_ni)							error_o <= 1'b0;		else
	if(is_moving)	begin
		if(timer >= BLADE_ERR_CNT_TSH)	error_o <= 1'b1;	end else
										error_o <= 1'b0;
end
endmodule