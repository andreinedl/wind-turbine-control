class scoreboard;
    // praguri/limite
    localparam HEAT_EN_TEMP = 30; // 5 grade
    localparam HEAT_DIS_TEMP = 35; // 10 grade

    bit expected_heat_state = 0; // variabila de stare pentru temperatura

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
        $error("[SCB-PASS] %s :: Expected = %d - Actual = %d", signal_name, value, value);
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
                if(output_tr.heat_o) pass("heat_o", expected_heat_state);
                else                 err("heat_o", expected_heat_state, output_tr.heat_o);

            end else if(input_tr.temp_value_i > HEAT_DIS_TEMP) begin
                expected_heat_state = 0;
                if(!output_tr.heat_o) pass("heat_o", expected_heat_state);
                else                  err("heat_o", expected_heat_state, output_tr.heat_o);

            end else begin
                if(output_tr.heat_o == expected_heat_state) 
                    pass("heat_o", expected_heat_state);
                else 
                    err("heat_o", expected_heat_state, output_tr.heat_o);
            end

        end
    endtask
endclass