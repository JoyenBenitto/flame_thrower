# Sample SDC Constraints for flame_thrower router design
# Adjust clock period, input/output delays and other constraints according to your design requirements

# Define the main clock
create_clock -name CLK -period 10.0 [get_ports CLK]

# Set clock uncertainty (for PVT variations)
set_clock_uncertainty 0.1 [get_clocks CLK]

# Input/Output delay constraints
set_input_delay -clock CLK -max 1.0 [all_inputs]
set_input_delay -clock CLK -min 0.5 [all_inputs]
set_output_delay -clock CLK -max 1.0 [all_outputs]
set_output_delay -clock CLK -min 0.5 [all_outputs]

# Set load capacitance on outputs
set_load 0.1 [all_outputs]

# Set drive strength on inputs
set_driving_cell -lib_cell sky130_fd_sc_hd__buf_1 [all_inputs]

# Set transition constraints
set_max_transition 1.0 [current_design]

# Set fanout constraints
set_max_fanout 10 [current_design]

# Set area constraint
# set_max_area 0 ;# Set to 0 for unlimited, or set a specific value

# False path constraints - add as needed for cross-clock domains or async paths
# set_false_path -from [get_clocks CLK1] -to [get_clocks CLK2]

# Multicycle path constraints - add as needed
# set_multicycle_path -setup 2 -from [get_pins FF1/Q] -to [get_pins FF2/D]
