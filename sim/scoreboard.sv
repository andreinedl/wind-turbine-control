class scoreboard;
    // praguri/limite
    localparam HEAT_EN_TEMP = 30; // 5 grade

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
                if(output_tr.heat_o) pass_cnt++;
                else begin
                    err_cnt++;
                    $display("Eroare: Incalzirea auxiliara este dezactivata chiar daca temperatura este sub prag.")
                end
            end

        end
    endtask
endclass