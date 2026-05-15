class scoreboard;
    // praguri/limite
    localparam HEAT_EN_TEMP = 30; // 5 grade
    localparam HEAT_DIS_TEMP = 35; // 10 grade
    localparam YAW_MAX_POS = 720;
    localparam MAX_WIND	   = 250;
    localparam MAX_RPM     = 350; //35 RPM
    localparam WIND_ANGLE_INCREASE_TSH = 120;
    
    // variabile de stare
    bit                 expected_heat_state = 0; // variabila de stare pentru temperatura
    int                 yaw_last_pos = 0;        // variabila de stare pentru pozitia nacelei
    int                 apb_trans_count = 0;     // variabila de stare pentru numarul de tranzactii efectuate pe apb
    logic [95:0]        apb_trans_data = '0;     // date trimise pe APB
    logic [95:0]        sensors_data;            // datele curente de la senzori


    // mailbox-uri
    mailbox input_mon2scb;
    mailbox output_mon2scb;
    mailbox server_mon2scb;
    
    // interfața virtuala pentru a putea asculta evenimentele de reset
    virtual input_interface v_input_intf;

    // coverage
    input_coverage input_cov;
    output_coverage output_cov;

    shortint pass_cnt; // counter ce numara tranzactiile ce sunt corecte
    shortint err_cnt;  // counter ce numara tranzactiile ce sunt eronate
    int no_transactions; // numarul total de tranzactii procesate

    function new(mailbox input_mon2scb, mailbox output_mon2scb, mailbox server_mon2scb, virtual input_interface v_input_intf);
        this.input_mon2scb = input_mon2scb;
        this.output_mon2scb = output_mon2scb;
        this.server_mon2scb = server_mon2scb;
        this.v_input_intf = v_input_intf;
        input_cov = new();
        output_cov = new();
    endfunction

    // printare mesaj de eroare pentru scoreboard
    // functie ce inlocuieste afisarea cu $error si incrementarea la fiecare eroare
    function void err(string signal_name, int expected_value, int actual_value);
        $error("[SCB-FAIL] %s :: Expected = %d - Actual = %d", signal_name, expected_value, actual_value);
        err_cnt++;
    endfunction

    // printare mesaj de succes pentru scoreboard
    // functie ce inlocuieste afisarea cu $display si incrementarea la fiecare pass al scoreboard-ului
    function void pass(string signal_name, int value);
        $display("[SCB-PASS] %s :: Expected = %d - Actual = %d", signal_name, value, value);
        pass_cnt++;
    endfunction

    task reset_scoreboard;
        // resetam variabilele de stare la o valoare initiala
        expected_heat_state = 0; 
        yaw_last_pos = 0;        
        apb_trans_count = 0;
        apb_trans_data = 0;
    endtask

    task main;
        input_transaction input_tr;
        output_transaction output_tr;
        server_transaction server_tr;
        fork
            forever begin
                //se preiau datele de la monitoare
                input_mon2scb.get(input_tr);
                output_mon2scb.get(output_tr);
                no_transactions++;

                // esantionam datele pentru coverage
                input_cov.sample(input_tr);
                output_cov.sample(output_tr);

                // stocare date pentru comparare cu cele trimise pe interfata APB
                // daca verificarea de pe interfata server nu s-a terminat
                // nu stocam noile date de la intrare si iesire in sensors_data
                if(apb_trans_count == 0)    sensors_data = {
                                                output_tr.error_feedback_o, 
                                                input_tr.wind_speed_i, 
                                                input_tr.wind_dir_i, 
                                                input_tr.yaw_angle_i, 
                                                input_tr.rpm_value_i, 
                                                input_tr.blade_angle_i, 
                                                input_tr.temp_value_i, 
                                                output_tr.yaw_pos_o, 
                                                output_tr.blade_pos_o, 
                                                output_tr.heat_o, 
                                                output_tr.em_brake_o
                                            };
                

                // verificare incalzire auxiliara turbina
                if(input_tr.temp_value_i < HEAT_EN_TEMP) begin // de ce ar trebui sa se activeze iesirea de caldura
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
                if(input_tr.wind_dir_i > YAW_MAX_POS) begin // daca directia din care bate vantul este mai mare de 720 () ...
                    if(input_tr.yaw_angle_i > YAW_MAX_POS) begin
                        if(output_tr.yaw_pos_o == 0)
                            pass("yaw_pos_o", 0);
                        else
                            err("yaw_pos_o", 0, output_tr.yaw_pos_o);
                    end
                    else begin
                        if(output_tr.yaw_pos_o == yaw_last_pos) 
                            pass("yaw_pos_o", yaw_last_pos);      
                        else 
                            err("yaw_pos_o", yaw_last_pos, output_tr.yaw_pos_o);
                    end
                end 
                else begin
                    if(output_tr.yaw_pos_o == input_tr.wind_dir_i) 
                        pass("yaw_pos_o", input_tr.wind_dir_i);
                    else 
                        err("yaw_pos_o", input_tr.wind_dir_i, output_tr.yaw_pos_o);

                    yaw_last_pos = output_tr.yaw_pos_o;
                end

                // verificam franarea de urgenta
                if(input_tr.rpm_value_i >= MAX_RPM) begin // daca se depaseste numarul maxim de rotatii pe minut, trebuie ca DUT-ul sa activeze franarea de urgenta
                    if(output_tr.em_brake_o) 
                        pass("em_brake_o", 1);
                    else                          
                        err("em_brake_o", 1, output_tr.em_brake_o);
                end 
                else begin
                    if(!output_tr.em_brake_o) 
                        pass("em_brake_o", 0);
                    else                          
                        err("em_brake_o", 0, output_tr.em_brake_o);
                end

                // verificare comanda pozitie pale
                if(input_tr.rpm_value_i >= MAX_RPM || input_tr.wind_speed_i > MAX_WIND) begin
                    // verificam daca turatia rotorului a depasit RPM-ul admis sau daca palele s-au dus la pozitia de 90 de grade cand viteza vantului a depasit valoarea maxima admisa
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
            end

            // thread pentru verificarea tranzactiilor APB
            forever begin
                server_mon2scb.get(server_tr);   

                // Asamblam datele primite in 3 transferuri consecutive
                apb_trans_data[apb_trans_count*32 +: 32] = server_tr.data;
                apb_trans_count++;

                if (apb_trans_count == 3) begin
                    $display("[SCB-INFO] Data sent through APB interface: %h", apb_trans_data);
                    if(apb_trans_data == sensors_data) begin
                        $display("[SCB-PASS] pwdata :: Expected = %h - Actual = %h", expected_apb_data, apb_trans_data);
                        pass_cnt++;
                    end else begin
                        $error("[SCB-FAIL] pwdata :: Expected = %h - Actual = %h", expected_apb_data, apb_trans_data);
                        err_cnt++;
                    end
                    apb_trans_count = 0; // resetam counter-ul
                end
            end

            // in cazul resetului resetam scoreboard-ul
            forever begin
                @(v_input_intf.reset_assert);
                reset_scoreboard();
            end

        join_none
    endtask
endclass