class scoreboard;
    // praguri/limite
    localparam HEAT_EN_TEMP = 30; // 5 grade
    localparam HEAT_DIS_TEMP = 35; // 10 grade
    localparam YAW_MAX_POS = 720;
    localparam MAX_WIND	   = 250;
    localparam MAX_RPM     = 350; //35 RPM
    localparam WIND_ANGLE_INCREASE_TSH = 120;

    bit expected_heat_state = 0; // variabila de stare pentru temperatura
    bit yaw_last_pos = 0;        // variabila de stare pentru pozitia nacelei

    // mailbox-uri
    mailbox input_mon2scb;
    mailbox output_mon2scb;
    
    // coverage
    input_coverage input_cov;
    output_coverage output_cov;

    shortint pass_cnt; // counter ce numara tranzactiile ce sunt corecte
    shortint err_cnt;  // counter ce numara tranzactiile ce sunt eronate

    function new(mailbox input_mon2scb, mailbox output_mon2scb);
        this.input_mon2scb = input_mon2scb;
        this.output_mon2scb = output_mon2scb;
        input_cov = new();
        output_cov = new();
    endfunction

    function err(string signal_name, int expected_value, int actual_value);
        $error("[SCB-FAIL] %s :: Expected = %d - Actual = %d", signal_name, expected_value, actual_value);
        err_cnt++;
    endfunction

    function pass(string signal_name, int value);
        $display("[SCB-PASS] %s :: Expected = %d - Actual = %d", signal_name, value, value);
        pass_cnt++;
    endfunction

    task main;
        input_transaction input_tr;
        output_transaction output_tr;

        forever begin
            //se preiau datele de la monitoare
            input_mon2scb.get(input_tr);
            output_mon2scb.get(output_tr);
            
            // esantionam datele pentru coverage
            input_cov.sample_function(input_tr);
            output_cov.sample_function(output_tr);
            
            // verificare incalzire auxiliara turbina
            if(input_tr.temp_value_i < HEAT_EN_TEMP) begin
                expected_heat_state = 1;
                if(output_tr.heat_o) 
                    pass("heat_o", expected_heat_state);
                else                 
                    err("heat_o", expected_heat_state, output_tr.heat_o);
            end 
            else if(input_tr.temp_value_i > HEAT_DIS_TEMP) begin
                expected_heat_state = 0;
                if(!output_tr.heat_o) 
                    pass("heat_o", expected_heat_state);
                else                  
                    err("heat_o", expected_heat_state, output_tr.heat_o);
            end 
            else begin
                if(output_tr.heat_o == expected_heat_state) 
                    pass("heat_o", expected_heat_state);
                else 
                    err("heat_o", expected_heat_state, output_tr.heat_o);
            end

            // verificare comanda nacela
            if(input_tr.wind_dir_i > YAW_MAX_POS) begin
                if(output_tr.yaw_pos_o == yaw_last_pos) 
                    pass("yaw_pos_o", yaw_last_pos);      
                else 
                    err("yaw_pos_o", yaw_last_pos, output_tr.yaw_pos_o);
            end 
            else begin
                yaw_last_pos = input_tr.wind_dir_i;
                if(output_tr.yaw_pos_o == input_tr.wind_dir_i) 
                    pass("yaw_pos_o", input_tr.wind_dir_i);
                else 
                    err("yaw_pos_o", input_tr.wind_dir_i, output_tr.yaw_pos_o);
            end

            // verificam franarea de urgenta
            if(input_tr.rpm_value_i >= MAX_RPM) begin
                if(output_tr.em_break_o) 
                    pass("em_break_o", 1);
                else                          
                    err("em_break_o", 1, output_tr.em_break_o);
            end 
            else begin
                if(!output_tr.em_break_o) 
                    pass("em_break_o", 0);
                else                          
                    err("em_break_o", 0, output_tr.em_break_o);
            end

            // verificare comanda pozitie pale
            if(input_tr.rpm_value_i >= MAX_RPM || input_tr.wind_speed_i > MAX_WIND) begin
                // verificam daca palele s-au dus la pozitia de 90 de grade
                if(output_tr.blade_pos_o == 180) 
                    pass("blade_pos_o", 180);
                else                             
                    err("blade_pos_o", 180, output_tr.blade_pos_o);
            end 
            else if(input_tr.wind_speed_i > WIND_ANGLE_INCREASE_TSH) begin
                int correct_value = (input_tr.wind_speed_i - WIND_ANGLE_INCREASE_TSH) / 2;
                //verificam pozitia palelor
                if(output_tr.blade_pos_o == correct_value)
                    pass("blade_pos_o", output_tr.blade_pos_o);
                else
                    err("blade_pos_o", correct_value, output_tr.blade_pos_o);
            end
            else begin
                //verificam pozitia palelor
                if(output_tr.blade_pos_o == 0)
                    pass("blade_pos_o", output_tr.blade_pos_o);
                else
                    err("blade_pos_o", 0, output_tr.blade_pos_o);
            end

            // verificare semnal error_feedback
            /*if(output_tr.em_brake_o) begin
                if(output_tr.error_feedback_o[3]) 
                    pass("error_feedback_o[3]", 1);
                else
                    err("error_feedback_o[3]", 0, output_tr.error_feedback_o);
            end*/

        end
    endtask
endclass