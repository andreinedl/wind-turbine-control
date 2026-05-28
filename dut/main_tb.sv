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

reg pready;

localparam CLK_PERIOD_NS = 20;

wind_turbine_control #(
    .CLK_PERIOD_NS(CLK_PERIOD_NS),
    .NS_PER_SEC(2)
) wind_turbine_inst (
    .clk_i(clk),
    .rst_ni(rst_n),

    // Interfața Senzori (Intrări)
    .wind_speed_i(wind_speed),       
    .wind_dir_i(wind_dir),          
    .yaw_angle_i(yaw_angle),        
    .rpm_value_i(rpm_value),        
    .blade_angle_i(blade_angle),        
    .temp_value_i(temp_value),       

    // Interfața Actuatoare (Ieșiri)
    .yaw_pos_o(yaw_pos),                
    .blade_pos_o(blade_pos),        
    .heat_o(heat),              
    .em_brake_o(em_brake),      
    
    // Status Sistem
    .error_feedback_o(error_feedback),
    
    //Interfata APB (control)
    .pready_i(pready),
    .paddr_o(paddr),                        
    .pwrite_o(pwrite),                      
    .pwdata_o(pwdata),
    .psel_o(psel),
    .penable_o(penable)
);

initial begin
    clk = 0;
    forever #(CLK_PERIOD_NS/2.0) clk = ~clk;
end

initial begin
    rst_n = 1;
    #10;
    rst_n = 0;
    repeat (2) @(posedge clk);
    rst_n = 1;
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
    #500;
    
    $display("\n========== SCENARIU 2: Vânt normal - direcție 0° ==========");
    wind_speed = 10'd160; // 16.0 m/s - condiții normale
    rpm_value = 9'd50;
    blade_angle = 8'd90;
    #500;
    
    $display("\n========== SCENARIU 3: Vânt normal - rotație nacela la 45° ==========");
    wind_dir = 10'd450;  // Vântul se mută la 45 grade
    yaw_angle = 10'd450;  // Simulăm că motorul a adus nacela la 45 grade
    rpm_value = 9'd60;
    blade_angle = 8'd95;
    #500;
    
    $display("\n========== SCENARIU 4: Vânt normal - rotație nacela la 90° ==========");
    wind_dir = 10'd900;   // 90 grade
    yaw_angle = 10'd900;  // Nacela la 90 grade
    rpm_value = 9'd65;
    blade_angle = 8'd100;
    #500;
    
    $display("\n========== SCENARIU 5: Vânt puternic (turație crescută) ==========");
    wind_speed = 10'd300; // 30.0 m/s - vânt puternic
    wind_dir = 10'd450;
    yaw_angle = 10'd450;
    rpm_value = 9'd150;   // RPM mare
    blade_angle = 8'd140; // Pale mai orizontale (pitch up)
    #500;
    
    $display("\n========== SCENARIU 6: Vânt foarte puternic (limitare RPM) ==========");
    wind_speed = 10'd400; // 40.0 m/s - vânt foarte puternic
    wind_dir = 10'd0;
    yaw_angle = 10'd0;
    rpm_value = 9'd400;   // RPM limitată
    blade_angle = 8'd160; // Pale aproape orizontale
    #500;
    
    $display("\n========== SCENARIU 7: Schimbare rapidă de direcție vânt (180°) ==========");
    wind_speed = 10'd160;
    wind_dir = 10'd0;      // Vânt din Nord
    yaw_angle = 10'd0;
    rpm_value = 9'd60;
    blade_angle = 8'd90;
    #300;
    
    yaw_angle = 10'd300;  // Aproximat la limita pe 10 biți
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
        #500;
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
    $stop;
end

// --- Monitor pentru a vedea datele trimise prin APB ---
initial begin
    $monitor("Time=%0t | APB: pready=%b psel=%b penable=%b | pwdata=0x%08h | Senzori: WSpeed=%0d WDir=%0d YawAng=%0d RPM=%0d BladeAng=%0d Temp=%0d | Out: YawPos=%0d BladePos=%0d Heat=%b EMBrake=%b Err=0x%h",
        $time, pready, psel, penable, pwdata,
        wind_speed, wind_dir, yaw_angle, rpm_value, blade_angle, temp_value,
        yaw_pos, blade_pos, heat, em_brake, error_feedback);
end
endmodule