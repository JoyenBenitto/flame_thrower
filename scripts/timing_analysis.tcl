# OpenSTA Timing Analysis Script for flame_thrower project
# To be used with the OpenSTA binary located at /home/joyen/Desktop/OpenSTA/app/sta

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

# Report clock and timing information
report_checks -path_delay max -fields {slew cap input nets fanout} -format full_clock -digits 3
report_checks -path_delay min -fields {slew cap input nets fanout} -format full_clock -digits 3
report_worst_slack -max
report_worst_slack -min
report_clock_skew

# Report timing summary
report_tns
report_wns

# Detailed reports
report_checks -path_delay max -group_count 10 -slack_max 0.0 -format full_clock
report_checks -path_delay min -group_count 10 -slack_max 0.0 -format full_clock

# Output detailed timing report
puts "Generating detailed timing reports in $::env(REPORT_DIR)..."

# Save worst slack to file
set worst_slack_max [report_worst_slack -max]
set worst_slack_min [report_worst_slack -min]

# Save max delay paths
report_checks -path_delay max -group_count 100 -format full_clock -output $::env(REPORT_DIR)/sta_report_max.txt

# Save min delay paths
report_checks -path_delay min -group_count 100 -format full_clock -output $::env(REPORT_DIR)/sta_report_min.txt

# Save clock skew report
report_clock_skew -output $::env(REPORT_DIR)/sta_clock_skew.txt

# Save summary for easier parsing
set summary_file [open "$::env(REPORT_DIR)/sta_summary.txt" w]
puts $summary_file "# STA Summary for $::env(TOP_MODULE)"
puts $summary_file "Worst Setup Slack: $worst_slack_max"
puts $summary_file "Worst Hold Slack: $worst_slack_min"
puts $summary_file "TNS: [report_tns]"
puts $summary_file "WNS: [report_wns]"
close $summary_file

# Force exit with return code 0
exit 0
