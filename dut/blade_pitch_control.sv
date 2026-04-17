module blade_pitch_control #(
    // Parametri pentru timp (50MHz * 30 secunde)
    // 50.000.000 * 30 = 1.500.000.000 (31 biți necesari, folosim 32)
    parameter logic [31:0] THIRTY_SEC_TICKS = 32'd1_500_000_000
)
(
    input  logic        clk_i,                // Semnal de ceas (50MHz)
    input  logic        rst_ni,               // Reset activ pe 0
    input  logic [9:0]  wind_speed_i,         // 0-600 (0-60.0 m/s)
    input  logic [8:0]  rpm_value_i,          // 0-350 (0-35.0 RPM)
    input  logic [7:0]  blade_angle_i,        // Unghi actual 0-180 (0-90.0 deg)
    
    output logic [7:0]  blade_pos_o, 		  // Unghi țintă 0-180
    output logic        error,                // Eroare timeout 30s
    output logic        em_break_o            // Frână de urgență (RPM > 350)
);

    logic [31:0] timer;
    logic        is_moving;

    // 1. Logica pentru Frâna de Urgență (em_break_o)
    // Se activează dacă RPM atinge sau depășește pragul de 350 (35.0 RPM)
    assign em_break_o = (rpm_value_i >= 9'd350);

    // 2. Calculul unghiului viitor (blade_pos_o)
    // Logica simplificată de control:
    always_comb begin
        if (em_break_o || wind_speed_i > 10'd250) begin
            // Dacă e frână de urgență sau vânt peste 25m/s, unghiul merge la 90 grade (valoare 180)
            blade_pos_o = 8'd180;
        end else if (wind_speed_i < 10'd40) begin
            // Vânt foarte slab (< 4m/s), unghiul rămâne la 0
            blade_pos_o = 8'd0;
        end else begin
            // Logica proporțională simplă: pe măsură ce vântul crește peste 12m/s (120), 
            // creștem unghiul pentru a limita puterea captată
            if (wind_speed_i > 10'd120)
                blade_pos_o = (wind_speed_i - 10'd120) / 2; 
            else
                blade_pos_o = 8'd0;
        end
    end

    // 3. Monitorizarea mișcării
    // Verificăm dacă unghiul actual este diferit de cel dorit
    assign is_moving = (blade_pos_o != blade_angle_i);

    // 4. Procesul de numărare și generare eroare (Timeout 30 secunde)
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            timer <= 32'd0;
            error <= 1'b0;
        end else begin
            if (is_moving) begin
                if (timer < THIRTY_SEC_TICKS) begin
                    timer <= timer + 1;
                    // Nu setăm eroarea încă, motorul are timp să lucreze
                end else begin
                    error <= 1'b1; // Timeout: Palele sunt blocate sau motorul e defect
                end
            end else begin
                // Dacă a ajuns la unghiul corect sau nu trebuie să se miște
                timer <= 32'd0;
                error <= 1'b0;
            end
        end
    end

endmodule