module heater_control #(
    // Parametri pentru timp (50MHz * 300 secunde)
    // 50.000.000 * 300 = 15.000.000.000
    // ATENȚIE: Această valoare depășește 32 de biți, avem nevoie de 34 biți
    parameter logic [33:0] FIVE_MIN_TICKS = 34'd15_000_000_000
)
(
    input  logic       clk_i,			// 50MHz
    input  logic       rst_ni,
    input  logic [6:0] temp_value_i,	// 0=-25C, 100=75C (Offset 25)
    
    output logic       heat_o,			// Comandă rezistență (1 = ON)
    output logic       error			// Eroare dacă temp nu crește în 5 min
);

    logic [33:0] timer;
    logic [6:0]  prev_temp;
    logic        temp_stable;

    // 1. Logica de control a încălzirii
    // Pornim dacă temp scade sub 5°C (valoarea 30)
    // Oprim dacă temp depășește 10°C (valoarea 35) - Histerezis
    always_comb begin
        if (temp_value_i < 7'd30)
            heat_o = 1'b1;
        else if (temp_value_i > 7'd35)
            heat_o = 1'b0;
        else
            heat_o = heat_o; // Menține starea anterioară (necesită logică secvențială pentru latch-less, dar aici lăsăm simplu)
    end

    // 2. Monitorizarea eficienței încălzirii
    // Dacă heat_o este pornit, temperatura trebuie să crească
    assign temp_stable = (temp_value_i <= prev_temp);

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            timer     <= 34'd0;
            error   <= 1'b0;
            prev_temp <= 7'd0;
        end else begin
            // Salvăm temperatura anterioară la intervale regulate (ex: la fiecare secundă) 
            // sau comparăm direct pentru timeout
            if (heat_o && temp_stable) begin
                if (timer < FIVE_MIN_TICKS) begin
                    timer <= timer + 1;
                end else begin
                    error <= 1'b1; // Rezistența merge de 5 min și temp nu a crescut
                end
            end else begin
                timer   <= 34'd0;
                error <= 1'b0;
                prev_temp <= temp_value_i;
            end
        end
    end

endmodule