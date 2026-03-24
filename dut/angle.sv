module yaw_angle_control #(
	// Parametri pentru timp (50MHz * 60 secunde)
    // 50.000.000 * 60 = 3.000.000.000 (32 biți)
  parameter logic [31:0] ONE_MINUTE_TICKS = 32'd3_000_000_000
  )
  
  (
    input  logic        clk_i,           // Semnal de ceas
    input  logic        rst_ni,         // Reset activ pe 0 (low)
    input  logic [9:0]  wind_dir_i,    // Direcția vântului
    input  logic [9:0]  yaw_angle_i,     // Poziția actuală a nacelei
    output logic [9:0]  yaw_pos_o,  // Unghiul țintă
    output logic        error          // Eroare dacă nu ajunge la țintă în 1 min
);
    
    logic [31:0] timer;
    logic        is_moving;


    assign yaw_pos_o = (wind_dir_i <= 10'd359) ? wind_dir_i : yaw_angle_i;
    assign is_moving = (yaw_pos_o != yaw_angle_i);

    // 3. Procesul de numărare și generare eroare
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            timer <= 32'd0;
            error <= 1'b0;
        end else begin
            if (is_moving) begin
                if (timer < ONE_MINUTE_TICKS) begin
                    timer <= timer + 1;
                    error <= 1'b0; // Încă are timp să se miște
                end else begin
                    error <= 1'b1; // A trecut minutul și nu a ajuns la destinație
                end
            end else begin
                // Dacă a ajuns la unghiul corect, resetăm cronometrul și eroarea
                timer <= 32'd0;
                error <= 1'b0;
            end
        end
    end

endmodule