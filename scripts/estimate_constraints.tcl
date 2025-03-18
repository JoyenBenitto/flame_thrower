# Timing constraints estimation script for OpenSTA
# This script helps analyze a design and suggest reasonable SDC constraints

# Read the Liberty library
set_cmd_units -time ns -capacitance pF -current mA -voltage V -resistance kOhm -distance um

# Set the Liberty model
read_liberty $::env(LIB_SKY130_PATH)

# Read synthesized netlist
read_verilog $::env(SYNTH_NETLIST)

# Link the design
link_design $::env(TOP_MODULE)

# Analyze design to find possible clocks
set potential_clocks [get_ports *clk*]
append potential_clocks [get_ports *clock*]
append potential_clocks [get_ports CLK]

puts "\n=== Potential Clock Ports ==="
foreach clk $potential_clocks {
    puts "$clk"
}

# Analyze ports
set all_input_ports [all_inputs]
set all_output_ports [all_outputs]

puts "\n=== Design Statistics ==="
puts "Total input ports: [llength $all_input_ports]"
puts "Total output ports: [llength $all_output_ports]"

# Suggest reasonable constraints
puts "\n=== Suggested SDC Constraints ==="
if {[llength $potential_clocks] > 0} {
    set suggested_clock [lindex $potential_clocks 0]
    puts "# Clock definition"
    puts "create_clock -name CLK -period 10.0 \[get_ports $suggested_clock\]"
    puts "set_clock_uncertainty 0.1 \[get_clocks CLK\]"
    
    # Input/output delays
    puts "\n# Input delays"
    puts "set_input_delay -clock CLK -max 1.0 \[remove_from_collection \[all_inputs\] \[get_ports $suggested_clock\]\]"
    puts "set_input_delay -clock CLK -min 0.5 \[remove_from_collection \[all_inputs\] \[get_ports $suggested_clock\]\]"
    
    puts "\n# Output delays"
    puts "set_output_delay -clock CLK -max 1.0 \[all_outputs\]"
    puts "set_output_delay -clock CLK -min 0.5 \[all_outputs\]"
} else {
    puts "WARNING: No clock ports detected. You need to manually identify the clock port."
    puts "# Example clock definition - adjust according to your design"
    puts "# create_clock -name CLK -period 10.0 \[get_ports <your_clock_port>\]"
}

puts "\n# Load and drive constraints"
puts "set_load 0.1 \[all_outputs\]"
puts "set_driving_cell -lib_cell sky130_fd_sc_hd__buf_1 \[all_inputs\]"

puts "\n# Transition and fanout constraints"
puts "set_max_transition 1.0 \[current_design\]"
puts "set_max_fanout 10 \[current_design\]"

# Force exit with return code 0
exit 0
