# Cale proiect - a se folosi "/" in loc de "\"
open_project "D:/Univ AN 3/TEE/tee-vivado/tee-vivado.xpr"
close_sim -quiet

set_property -name {xsim.simulate.functional_coverage} -value {true} -objects [get_filesets sim_1]

set_property -name {xelab.more_options} -value {-cov_db_dir ./cov_db -cov_db_name coverage} -objects [get_filesets sim_1]
set_property -name {xsim.more_options} -value {-cov_db_dir ./cov_db -cov_db_name coverage} -objects [get_filesets sim_1]

puts "Pornire simulare..."
launch_simulation

puts "Rulare teste..."
run all

puts "Generare raport coverage..."
set proj_dir [get_property DIRECTORY [current_project]]

exec xcrg -dir $proj_dir/[current_project].sim/sim_1/behav/xsim/cov_db -db_name coverage -report_dir $proj_dir/coverage_report -report_format html

puts "Raport generat cu succes."