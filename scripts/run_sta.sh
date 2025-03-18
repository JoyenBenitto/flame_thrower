#!/bin/bash

# Run OpenSTA timing analysis for flame_thrower

# Base directories
PROJECT_DIR="$(pwd)"
OPENSTA_BIN="/home/joyen/Desktop/OpenSTA/app/sta"
SCRIPTS_DIR="$PROJECT_DIR/scripts"
SYNTH_DIR="$PROJECT_DIR/build/synth"
REPORT_DIR="$SYNTH_DIR/reports"

# Check if OpenSTA binary exists
if [ ! -x "$OPENSTA_BIN" ]; then
    echo "ERROR: OpenSTA binary not found at $OPENSTA_BIN"
    exit 1
fi

# Setup required variables
LIB_SKY130_PATH="$PROJECT_DIR/OpenROAD-flow-scripts/flow/platforms/sky130hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
SYNTH_NETLIST="$SYNTH_DIR/mk_router_synth.v"
TOP_MODULE="mk_router"
SDC_FILE="$SYNTH_DIR/mk_router.sdc"

# Create reports directory if it doesn't exist
mkdir -p "$REPORT_DIR"

# Check if files exist
if [ ! -f "$LIB_SKY130_PATH" ]; then
    echo "ERROR: Liberty file not found at $LIB_SKY130_PATH"
    echo "Searching for alternative liberty files..."
    POTENTIAL_LIBS=$(find "$PROJECT_DIR" -name "*.lib" | grep -i sky130)
    if [ ! -z "$POTENTIAL_LIBS" ]; then
        echo "Found potential liberty files:"
        echo "$POTENTIAL_LIBS"
        echo "Please update the script with the correct path."
    fi
    exit 1
fi

if [ ! -f "$SYNTH_NETLIST" ]; then
    echo "ERROR: Synthesized netlist not found at $SYNTH_NETLIST"
    echo "Please run 'make synth' first."
    exit 1
fi

# Check if SDC file exists, use sample if not
if [ ! -f "$SDC_FILE" ]; then
    echo "WARNING: SDC file not found at $SDC_FILE"
    echo "Using sample constraints file"
    if [ -f "$SCRIPTS_DIR/sample_constraints.sdc" ]; then
        cp "$SCRIPTS_DIR/sample_constraints.sdc" "$SDC_FILE"
        echo "Copied sample constraints to $SDC_FILE"
    else
        echo "ERROR: Sample constraints file not found either."
        exit 1
    fi
fi

# Export environment variables for use in Tcl script
export LIB_SKY130_PATH
export SYNTH_NETLIST
export TOP_MODULE
export SDC_FILE
export REPORT_DIR

# Run the timing analysis
echo "Running OpenSTA timing analysis..."

# Create a temporary OpenSTA script that will be run directly
TMP_STA_SCRIPT="$REPORT_DIR/run_sta_temp.tcl"

# Create a direct script with all commands for better debugging
cat > "$TMP_STA_SCRIPT" << EOL
# To be used with the OpenSTA binary
set_cmd_units -time ns -capacitance pF -current mA -voltage V -resistance kOhm -distance um

# Set the Liberty model
read_liberty "$LIB_SKY130_PATH"
puts "Liberty file read: $LIB_SKY130_PATH"

# Read synthesized netlist
read_verilog "$SYNTH_NETLIST"
puts "Netlist read: $SYNTH_NETLIST"

# Link the design (make sure the top module is correctly specified)
link_design $TOP_MODULE
puts "Linked design for top module: $TOP_MODULE"

# Read SDC constraints
if { [file exists "$SDC_FILE"] } {
    read_sdc "$SDC_FILE"
    puts "SDC file read: $SDC_FILE"
} else {
    # Create a basic clock constraint if no SDC file exists
    create_clock -name clk -period 10 {CLK}
    puts "No SDC file found. Created default clock with 10ns period."
}

# Report clock and timing information
puts "\n==== TIMING REPORT ===="

# Generate detailed reports
puts "\n==== SETUP TIMING PATHS ===="
set worst_paths_max [report_checks -path_delay max -fields {slew cap input nets fanout} -format full_clock -digits 3 -group_count 10]
puts "$worst_paths_max"

puts "\n==== HOLD TIMING PATHS ===="
set worst_paths_min [report_checks -path_delay min -fields {slew cap input nets fanout} -format full_clock -digits 3 -group_count 10]
puts "$worst_paths_min"

puts "\n==== WORST SLACK (SETUP) ===="
set worst_slack_max [report_worst_slack -max]
puts "$worst_slack_max"

puts "\n==== WORST SLACK (HOLD) ===="
set worst_slack_min [report_worst_slack -min]
puts "$worst_slack_min"

puts "\n==== CLOCK SKEW ===="
set clock_skew [report_clock_skew]
puts "$clock_skew"

puts "\n==== TNS ===="
set tns [report_tns]
puts "$tns"

puts "\n==== WNS ===="
set wns [report_wns]
puts "$wns"

# Save reports to files
report_checks -path_delay max -group_count 100 -format full_clock -output "$::env(REPORT_DIR)/sta_report_max.txt"
report_checks -path_delay min -group_count 100 -format full_clock -output "$::env(REPORT_DIR)/sta_report_min.txt"
report_clock_skew -output "$::env(REPORT_DIR)/sta_clock_skew.txt"

# Save summary for easier parsing
set summary_file [open "$::env(REPORT_DIR)/sta_summary.txt" w]
puts $summary_file "# STA Summary for $::env(TOP_MODULE)"
puts $summary_file "Worst_Setup_Slack: $worst_slack_max"
puts $summary_file "Worst_Hold_Slack: $worst_slack_min"
puts $summary_file "TNS: $tns"
puts $summary_file "WNS: $wns"
close $summary_file

# Finished successfully
puts "OpenSTA timing analysis completed successfully"
exit 0
EOL

echo "Created temporary OpenSTA script at $TMP_STA_SCRIPT"

# Try several methods to run OpenSTA, ensuring it exits properly
echo "Attempting to run OpenSTA with proper exit handling"

# Method 1: Custom wrapper script (preferred)
if [ -x "$SCRIPTS_DIR/sta_wrapper.sh" ]; then
    echo "Running OpenSTA using wrapper script"
    "$SCRIPTS_DIR/sta_wrapper.sh" "$OPENSTA_BIN" "$TMP_STA_SCRIPT" "$REPORT_DIR/sta_full_report.log"
    STA_EXIT_CODE=$?
# Method 2: Expect script
elif [ -x "$SCRIPTS_DIR/run_sta_expect.sh" ]; then
    echo "Running OpenSTA using expect script"
    "$SCRIPTS_DIR/run_sta_expect.sh" "$OPENSTA_BIN" "$TMP_STA_SCRIPT" "$REPORT_DIR/sta_full_report.log"
    STA_EXIT_CODE=$?
# Method 3: Tcl wrapper script
elif [ -f "$SCRIPTS_DIR/sta_wrapper.tcl" ]; then
    echo "Running OpenSTA using Tcl wrapper script"
    timeout 300s $OPENSTA_BIN "$SCRIPTS_DIR/sta_wrapper.tcl" "$TMP_STA_SCRIPT" 2>&1 | tee "$REPORT_DIR/sta_full_report.log"
    STA_EXIT_CODE=$?
# Method 4: Fallback to direct execution with timeout
else
    echo "WARNING: No wrapper scripts found, falling back to timeout method"
    echo "Running OpenSTA with command: $OPENSTA_BIN $TMP_STA_SCRIPT"
    timeout 300s $OPENSTA_BIN $TMP_STA_SCRIPT 2>&1 | tee "$REPORT_DIR/sta_full_report.log"
    STA_EXIT_CODE=$?
fi

echo "OpenSTA completed with exit code: $STA_EXIT_CODE"

# Check exit code
if [ $STA_EXIT_CODE -ne 0 ] && [ $STA_EXIT_CODE -ne 124 ]; then
    echo "WARNING: OpenSTA exited with non-zero code: $STA_EXIT_CODE"
fi

# Check if OpenSTA timed out
if [ $? -eq 124 ]; then
    echo "ERROR: OpenSTA timed out after 5 minutes. This may indicate an issue with the timing analysis."
    exit 1
fi

echo ""
echo "Timing analysis completed. Reports saved to $REPORT_DIR"
echo "Summary of timing violations:"
grep -A 3 "Worst slack" "$REPORT_DIR/sta_full_report.log"

# Check for timing violations
if grep -q "VIOLATED" "$REPORT_DIR/sta_full_report.log"; then
    echo "
WARNING: Timing violations detected!"
else
    echo "
SUCCESS: No timing violations detected."
fi

# Generate timing summary YAML with actual timing data
echo "
Generating timing summary with actual timing data..."
"$SCRIPTS_DIR/generate_timing_summary.sh"
echo "Timing summary generated in $REPORT_DIR/timing_summary.yaml"
