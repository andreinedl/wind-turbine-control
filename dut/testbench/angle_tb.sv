`timescale 1ns / 1ps

module yaw_angle_control_tb();

    // Semnale de test
    logic        clk;					
    logic        rst_n;                 
    logic [9:0]  wind_angle;            
    logic [9:0]  yaw_angle;             
    wire  [9:0]  future_angle;          
    wire         error;                 

    // Instanțierea modulului (DUT - Device Under Test)
    // Suprascriem parametrul de timp pentru a nu aștepta un minut real în simulare
    yaw_angle_control #(
        .ONE_MINUTE_TICKS(32'd10) // Eroarea va apărea după 100 de cicli, nu miliarde
    ) dut (
        .clk_i(clk),
        .rst_ni(rst_n),
        .wind_dir_i(wind_angle),
        .yaw_angle_i(yaw_angle),
        .yaw_pos_o(future_angle),
        .error(error)
    );

    // Generarea ceasului (perioadă de 10ns -> 100MHz)
    always #5 clk = ~clk;

    initial begin
        // --- 1. Inițializare ---
        clk = 0;
        rst_n = 0;
        wind_angle = 10'd0;
        yaw_angle = 10'd0;

        #20 rst_n = 1; // Eliberăm resetul după 20ns
        #10;

        // --- 2. Test: Funcționare normală (Aliniere rapidă) ---
        $display("Test 1: Aliniere corecta");
        wind_angle = 10'd45; // Vântul se mută la 45 grade
        #50;                // Așteptăm puțin
        yaw_angle = 10'd45;  // Simulăm că motorul a adus nacela la 45 grade
        #20;
        if (error == 0) $display("Pas: Sistemul s-a aliniat la timp, nicio eroare.");

        // --- 3. Test: Eroare (Timeout) ---
        $display("Test 2: Simulare blocaj (Timeout)");
        wind_angle = 10'd90; // Vântul se mută la 90 grade
        // NU modificăm yaw_angle, simulăm că motorul e blocat
        
        #1100; // Așteptăm peste cei 100 de cicli setați (100 * 10ns = 1000ns)
        
        if (error == 1) 
            $display("Pas: Eroare detectata corect după timeout!");
        else 
            $display("Esec: Eroarea nu a fost activata.");

        // --- 4. Test: Resetare eroare ---
        $display("Test 3: Recuperare din eroare");
        yaw_angle = 10'd90; // În sfârșit nacela ajunge la destinație
        #20;
        if (error == 0) $display("Pas: Eroarea s-a șters după aliniere.");

        #100;
        $display("Simulare finalizată.");
        $finish;
    end

    // Monitorizare în consolă
    initial begin
        $monitor("Time=%0t | Wind=%0d | Yaw=%0d | Future=%0d | Error=%b", 
                 $time, wind_angle, yaw_angle, future_angle, error);
    end

endmodule