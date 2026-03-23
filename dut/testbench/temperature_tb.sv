`timescale 1ns / 1ps

module heater_control_tb();

    logic       clk;				
    logic       rst_n;
    logic [6:0] temp_value;
    wire        heat_o;
    wire        error_o;

    // Instanțiere cu timeout redus pentru simulare
    heater_control #(
        .FIVE_MIN_TICKS(34'd20)
    ) dut (
        .clk_i(clk),					  
        .rst_ni(rst_n),                 
        .temp_value_i(temp_value),      
        .heat_o(heat_o),                
        .error(error_o)               
    );                                  

    // Ceas 100MHz
    always #5 clk = ~clk;

    initial begin
        // --- 1. Inițializare ---
        clk = 0;
        rst_n = 0;
        temp_value = 7'd50; // 25 grade C (Normal)

        #20 rst_n = 1;
        #20;

        // --- 2. Test: Activare încălzire ---
        $display("Test 1: Scădere temperatură sub prag");
        temp_value = 7'd25; // 0 grade C
        #20;
        if (heat_o) $display("Pas: Rezistența a pornit la 0C.");

        // --- 3. Test: Eroare (Temp nu crește) ---
        $display("Test 2: Simulare rezistență defectă (Timeout)");
        // Menținem temp_value la 25 deși heat_o e pornit
        #2500; // Așteptăm peste cei 200 cicli (2000ns)
        
        if (error_o) $display("Pas: Eroare detectată! Rezistența nu încălzește.");

        // --- 4. Test: Recuperare ---
        $display("Test 3: Creștere temperatură (Funcționare OK)");
        temp_value = 7'd45; // 20 grade C
        #50;
        if (!heat_o && !error_o) 
            $display("Pas: Încălzirea s-a oprit și eroarea a dispărut.");

        #100;
        $finish;
    end

    initial begin
        $monitor("T=%0t | Temp_Raw=%0d (Actual=%0d C) | Heat=%b | Error=%b", 
                 $time, temp_value, (temp_value - 25), heat_o, error_o);
    end

endmodule