program rst_test(
    input_interface input_intf, 
    output_interface output_intf, 
    server_interface server_intf
);

environment env;
initial begin
    env = new(input_intf, output_intf, server_intf);

    $display("[RESET-TEST] Single-run reset test");

    env.gen.repeat_count = 500;

    fork 
        begin
            env.run();
        end

        begin
            #300;
            $display("[RESET-TEST] Async reset triggered at %0t!", $time);
            -> input_intf.reset_assert;

            #300;
            $display("[RESET-TEST] Releasing reset at %0t...", $time);
            -> input_intf.reset_deassert;
        end
    join
end

endprogram