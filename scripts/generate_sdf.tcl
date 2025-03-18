# SDF generation script for OpenSTA

# Read the Liberty library
set_cmd_units -time ns -capacitance pF -current mA -voltage V -resistance kOhm -distance um

# Set the Liberty model
read_liberty $::env(LIB_SKY130_PATH)

# Read synthesized netlist
read_verilog $::env(SYNTH_NETLIST)

# Link the design (make sure the top module is correctly specified)
link_design $::env(TOP_MODULE)

# Read SDC constraints
read_sdc $::env(SDC_FILE)

# Generate SDF file
write_sdf $::env(SDF_OUTPUT)

# Force exit with return code 0
exit 0
