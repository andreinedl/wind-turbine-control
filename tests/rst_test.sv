program rst_test(
    input_interface input_intf, 
    output_interface output_intf, 
    server_interface server_intf
);

environment env;
initial begin
    // Instantierea mediului de testare
    env = new(input_intf, output_intf, server_intf);

    $display("[RESET-TEST] Single-run reset test");

    // Generam un numar mare de tranzactii pentru a ne asigura ca sistemul 
    env.gen.repeat_count = 500;

    // Folosim fork si join pentru a rula doua fire de executie in paralel:
    // rularea testului
    // trimiterea secventei de reset
    fork 
        begin
            // Thread 1: porneste tranzactiile si monitoarele
            env.run();
        end

        begin
            // Thread 2: asteapta 300 de unitati de timp, apoi forteaza reset-ul
            #300;
            $display("[RESET-TEST] Async reset triggered at %0t!", $time);
            // Semnalam faptul ca am intrat in reset folosind un event
            -> input_intf.reset_assert;

            #300;
            $display("[RESET-TEST] Releasing reset at %0t...", $time);
            // Semnalam reluarea simularii folosind un event
            -> input_intf.reset_deassert;
        end
    join
end

endprogram