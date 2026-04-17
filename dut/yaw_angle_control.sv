module yaw_angle_control #(
	// Parametri pentru timp (50MHz * 60 secunde)
    // 50.000.000 * 60 = 3.000.000.000 (32 biți)
  parameter logic [31:0] ONE_MINUTE_TICKS = 32'd3_000_000_000
  )
  
  (
    input  logic        clk_i,			// Semnal de ceas
    input  logic        rst_ni,			// Reset activ pe 0 (low)
    input  logic [9:0]  wind_dir_i,		// Direcția vântului
    input  logic [9:0]  yaw_angle_i,	// Poziția actuală a nacelei
    output logic [9:0]  yaw_pos_o,		// Unghiul țintă
    output logic        error			// Eroare dacă nu ajunge la țintă în 1 min
);
    
    logic [31:0] timer;
    logic        is_moving;


    assign yaw_pos_o = (wind_dir_i <= 10'd359) ? wind_dir_i : yaw_angle_i;
    assign is_moving = (yaw_pos_o != yaw_angle_i);

    // Procesul de numărare și generare eroare
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) 
            timer <= 32'd0;
		else begin
            if (is_moving) 
				if (timer < ONE_MINUTE_TICKS) 
					timer <= timer + 1;
				else 
					timer <= 32'd0;
			else 
				timer <= 32'd0;
            end
        end


	always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            error <= 1'b0;
		else begin
            if (is_moving) 
				if (timer < ONE_MINUTE_TICKS)
					error <= 1'b0; 
				else
					error <= 1'b1; 
			else 
                error <= 1'b0;
            end
        end

endmodule