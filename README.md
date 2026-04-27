# Proiect TEE - Wind Turbine Control

Proiect in care am construit un DUT pentru controlul unei turbine eoliene si un mediu de verificare in SystemVerilog.

## DUT

Top-level: [dut/wind_turbine_control.sv](dut/wind_turbine_control.sv)

Intrari principale:
- viteza vantului
- directia vantului
- unghi nacela
- RPM
- unghi pale
- temperatura

Iesiri principale:
- comanda yaw
- comanda pitch
- comanda incalzire
- emergency brake
- error feedback

Module integrate:
- [dut/wind_turbine_control.sv](dut/wind_turbine_control.sv)
- [dut/yaw_angle_control.sv](dut/yaw_angle_control.sv)
- [dut/blade_pitch_control.sv](dut/blade_pitch_control.sv)
- [dut/heater_control.sv](dut/heater_control.sv)
- [dut/apb_master.sv](dut/apb_master.sv)

## Mediu De Verificare

Top simulare: [sim/testbench.sv](sim/testbench.sv)
Environment: [sim/environment.sv](sim/environment.sv)

Componente:
- Generator: [generators/input_generator.sv](generators/input_generator.sv)
- Driver: [drivers/input_driver.sv](drivers/input_driver.sv)
- Monitoare: [monitors/input_monitor.sv](monitors/input_monitor.sv), [monitors/output_monitor.sv](monitors/output_monitor.sv), [monitors/server_monitor.sv](monitors/server_monitor.sv)
- Tranzactii: [transactions/input_transaction.sv](transactions/input_transaction.sv), [transactions/output_transaction.sv](transactions/output_transaction.sv), [transactions/server_transaction.sv](transactions/server_transaction.sv)
- Interfete cu assertii: [interfaces/input_interface.sv](interfaces/input_interface.sv), [interfaces/output_interface.sv](interfaces/output_interface.sv), [interfaces/server_interface.sv](interfaces/server_interface.sv)