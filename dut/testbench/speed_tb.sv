`timescale 1ns / 1ps

module blade_pitch_control_tb();

    // Semnale de test
    logic       clk;					        
    logic       rst_n;                           
    logic [9:0] wind_speed;                 
    logic [8:0] rpm_value;                  
    logic [7:0] blade_angle;                
                                            
    wire  [7:0] future_blade_angle;         
    wire        error;                              
    wire        em_break;                       

    // Instanțierea modulului (DUT)
    // Reducem THIRTY_SEC_TICKS pentru testare rapidă
    // Eroarea ar trebui să apară după 100 de cicli de ceas
    blade_pitch_control #(
        .THIRTY_SEC_TICKS(32'd10) 
    ) dut (
        .clk_i(clk),
        .rst_ni(rst_n),
        .wind_speed_i(wind_speed),
        .rpm_value_i(rpm_value),
        .blade_angle_i(blade_angle),
        .blade_pos_o(future_blade_angle),
        .error(error),
        .em_break_o(em_break)
    );

    // Generarea ceasului (100MHz -> perioadă 10ns)
    always #5 clk = ~clk;

    initial begin
        // --- 1. Inițializare ---
        clk = 0;
        rst_n = 0;
        wind_speed = 10'd0;
        rpm_value = 9'd0;
        blade_angle = 8'd0;

        #20 rst_n = 1; 
        #10;

        // --- 2. Test: Funcționare Normală & Mișcare ---
        $display("\n--- Test 1: Ajustare unghi (Vant moderat) ---");
        wind_speed = 10'd160; // 16.0 m/s -> Ar trebui să rezulte un unghi > 0
        #20;
        $display("Target calculat: %d", future_blade_angle);
        
        // Simulăm mișcarea motorului către target
        #50;
        blade_angle = future_blade_angle; 
        #20;
        if (error == 0) $display("Pas: Unghiul s-a ajustat corect, nicio eroare.");

        // --- 3. Test: Frână de Urgență (RPM prea mare) ---
        $display("\n--- Test 2: Over-speed (Frana de urgenta) ---");
        rpm_value = 9'd355; // Peste pragul de 350
        #20;
        if (em_break == 1 && future_blade_angle == 180)
            $display("Pas: Frana EM activata si palele s-au dus la 90 grade.");
        else
            $display("Esec: Frana EM nu a reactionat!");

        // Resetăm RPM pentru următorul test
        rpm_value = 9'd200;
        #20;

        // --- 4. Test: Eroare Timeout (Motor blocat) ---
        $display("\n--- Test 3: Simulare blocaj motor (Timeout) ---");
        wind_speed = 10'd280; // Vânt puternic -> target 180 (90 deg)
        // NU actualizăm blade_angle (simulăm blocaj)
        
        #1100; // Așteptăm peste cei 100 de cicli (100 * 10ns = 1000ns)
        
        if (error == 1) 
            $display("Pas: Eroare detectata corect dupa 100 cicli!");
        else 
            $display("Esec: Eroarea de timeout nu a aparut.");

        // --- 5. Test: Recuperare din eroare ---
        $display("\n--- Test 4: Recuperare din eroare ---");
        blade_angle = 8'd180; // Deblocăm palele manual în simulare
        #20;
        if (error == 0) $display("Pas: Semnalul de eroare s-a sters după aliniere.");

        #100;
        $display("\nToate testele au fost finalizate.");
        $finish;
    end

    // Monitorizare în consolă pentru debug rapid
    initial begin
        $monitor("T=%0t | Wind=%0.1f m/s | RPM=%0.1f | Angle=%0.1f | Target=%0.1f | Err=%b | Break=%b", 
                 $time, 
                 wind_speed/10.0, 
                 rpm_value/10.0, 
                 blade_angle/2.0, 
                 future_blade_angle/2.0, 
                 error, 
                 em_break);
    end

endmodule