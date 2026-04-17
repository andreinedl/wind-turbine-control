onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /wind_turbine_control_tb/clk
add wave -noupdate /wind_turbine_control_tb/rst_n
add wave -noupdate /wind_turbine_control_tb/wind_speed
add wave -noupdate /wind_turbine_control_tb/wind_dir
add wave -noupdate /wind_turbine_control_tb/yaw_angle
add wave -noupdate /wind_turbine_control_tb/rpm_value
add wave -noupdate /wind_turbine_control_tb/blade_angle
add wave -noupdate /wind_turbine_control_tb/temp_value
add wave -noupdate /wind_turbine_control_tb/yaw_pos
add wave -noupdate /wind_turbine_control_tb/blade_pos
add wave -noupdate /wind_turbine_control_tb/heat
add wave -noupdate /wind_turbine_control_tb/em_brake
add wave -noupdate /wind_turbine_control_tb/error_feedback
add wave -noupdate /wind_turbine_control_tb/paddr
add wave -noupdate /wind_turbine_control_tb/pwrite
add wave -noupdate /wind_turbine_control_tb/pwdata
add wave -noupdate /wind_turbine_control_tb/psel
add wave -noupdate /wind_turbine_control_tb/penable
add wave -noupdate /wind_turbine_control_tb/start
add wave -noupdate /wind_turbine_control_tb/pready
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 562
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {667 ps}
