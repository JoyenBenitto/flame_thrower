#!/bin/bash

# Script to extract timing information from reports and generate a detailed YAML summary

# Set up the environment
REPORT_DIR="./build/synth/reports"
SUMMARY_YAML="${REPORT_DIR}/timing_summary.yaml"
TOP_MODULE="mk_router"
SYNTH_DIR="./build/synth"

# Make sure the report directory exists
mkdir -p "${REPORT_DIR}"

# Initialize YAML file
cat > "${SUMMARY_YAML}" << EOL
---
# Timing Analysis Summary
# Generated: $(date)
# Design: ${TOP_MODULE}

design_info:
  top_module: ${TOP_MODULE}
  netlist: ${SYNTH_DIR}/${TOP_MODULE}_synth.v
  sdf_file: ${SYNTH_DIR}/${TOP_MODULE}.sdf
  sdc_file: ${SYNTH_DIR}/${TOP_MODULE}.sdc

timing_summary:
  # Will be populated with timing data

reports:
  # Standard Timing Analysis reports
  - name: "Full STA Log"
    file: "sta_full_report.log"
    description: "Complete log output from OpenSTA timing analysis run"
    
  - name: "Maximum Delay Paths"
    file: "sta_report_max.txt"
    description: "Detailed report of worst-case (setup) timing paths"
    
  - name: "Minimum Delay Paths"
    file: "sta_report_min.txt"
    description: "Detailed report of best-case (hold) timing paths"
    
  - name: "Clock Skew Report"
    file: "sta_clock_skew.txt"
    description: "Report of clock skew between timing paths"
    
  - name: "Background STA Log"
    file: "sta_background.log"
    description: "Log from running OpenSTA in background (non-blocking mode)"

  # Constraint-related reports
  - name: "Constraint Estimation"
    file: "constraint_estimation.log"
    description: "Generated timing constraints based on design analysis"
    
  # SDF Generation reports
  - name: "SDF Generation Log"
    file: "sdf_generation.log"
    description: "Log from SDF file generation process"
    
commands:
  run_sta: "make sta"
  run_sta_background: "make sta_background"
  generate_sdf: "make generate_sdf"
  estimate_constraints: "make estimate_constraints"
  view_report: "make timing_report"
  view_summary: "make timing_summary"
  show_catalog: "make timing_catalog"
EOL

# Extract timing data if available
if [ -f "${REPORT_DIR}/sta_full_report.log" ] && [ -s "${REPORT_DIR}/sta_full_report.log" ]; then
  echo "Extracting timing data from OpenSTA reports..."
  
  # Extract primary timing data
  # First try looking for direct markers in the log file with different patterns
  WORST_SLACK_SETUP=$(grep -A 2 "WORST SLACK (SETUP)" "${REPORT_DIR}/sta_full_report.log" | grep -o "worst slack max [0-9][0-9.]*" | awk '{print $NF}')
  WORST_SLACK_HOLD=$(grep -A 2 "WORST SLACK (HOLD)" "${REPORT_DIR}/sta_full_report.log" | grep -o "worst slack min [0-9][0-9.]*" | awk '{print $NF}')
  TNS=$(grep -A 2 "TNS" "${REPORT_DIR}/sta_full_report.log" | grep -o "tns max [0-9][0-9.]*" | awk '{print $NF}')
  WNS=$(grep -A 2 "WNS" "${REPORT_DIR}/sta_full_report.log" | grep -o "wns max [0-9][0-9.]*" | awk '{print $NF}')
  
  # If values not found, try alternate format from summary file
  if [ -z "$WORST_SLACK_SETUP" ] && [ -f "${REPORT_DIR}/sta_summary.txt" ]; then
    WORST_SLACK_SETUP=$(grep "Worst_Setup_Slack" "${REPORT_DIR}/sta_summary.txt" | awk -F":" '{print $2}' | xargs)
  fi
  
  if [ -z "$WORST_SLACK_HOLD" ] && [ -f "${REPORT_DIR}/sta_summary.txt" ]; then
    WORST_SLACK_HOLD=$(grep "Worst_Hold_Slack" "${REPORT_DIR}/sta_summary.txt" | awk -F":" '{print $2}' | xargs)
  fi
  
  if [ -z "$TNS" ] && [ -f "${REPORT_DIR}/sta_summary.txt" ]; then
    TNS=$(grep "TNS" "${REPORT_DIR}/sta_summary.txt" | awk -F":" '{print $2}' | xargs)
  fi
  
  if [ -z "$WNS" ] && [ -f "${REPORT_DIR}/sta_summary.txt" ]; then
    WNS=$(grep "WNS" "${REPORT_DIR}/sta_summary.txt" | awk -F":" '{print $2}' | xargs)
  fi
  
  # If any values are still empty, try further alternatives
  if [ -z "$WORST_SLACK_SETUP" ]; then
    WORST_SLACK_SETUP=$(grep "Worst Setup Slack" "${REPORT_DIR}/sta_full_report.log" | grep -v "checking" | awk '{print $NF}' | head -1)
  fi
  
  if [ -z "$WORST_SLACK_HOLD" ]; then
    WORST_SLACK_HOLD=$(grep "Worst Hold Slack" "${REPORT_DIR}/sta_full_report.log" | grep -v "checking" | awk '{print $NF}' | head -1)
  fi
  
  # Extract clock information
  CLOCK_PERIOD=$(grep -A 1 "create_clock" "${REPORT_DIR}/sta_full_report.log" | grep "period" | head -1 | awk '{print $4}')
  if [ -z "$CLOCK_PERIOD" ]; then
    CLOCK_PERIOD="10.0 (default)"  # Assume default if not found
  fi
  
  # Get clock names
  CLOCKS=$(grep "create_clock" "${REPORT_DIR}/sta_full_report.log" | grep -oP "\\-name \\K\\S+" | sort -u | tr '\n' ' ')
  if [ -z "$CLOCKS" ]; then
    CLOCKS="clk (default)"  # Default name if not found
  fi
  
  # Count timing violations
  if [ -f "${REPORT_DIR}/sta_report_max.txt" ]; then
    SETUP_VIOLATIONS=$(grep -c "VIOLATED" "${REPORT_DIR}/sta_report_max.txt" 2>/dev/null || echo "0")
    # Clean any extra output - ensure it's just a number
    SETUP_VIOLATIONS=$(echo "$SETUP_VIOLATIONS" | tr -d '
' | awk '{print $1}')
  else
    # Try to find violations directly in the log file
    SETUP_VIOLATIONS=$(grep -c "VIOLATED" "${REPORT_DIR}/sta_full_report.log" 2>/dev/null || echo "0")
    SETUP_VIOLATIONS=$(echo "$SETUP_VIOLATIONS" | tr -d '
' | awk '{print $1}')
  fi

  if [ -f "${REPORT_DIR}/sta_report_min.txt" ]; then
    HOLD_VIOLATIONS=$(grep -c "VIOLATED" "${REPORT_DIR}/sta_report_min.txt" 2>/dev/null || echo "0")
    HOLD_VIOLATIONS=$(echo "$HOLD_VIOLATIONS" | tr -d '
' | awk '{print $1}')
  else
    # We might need to count differently for hold violations in the log
    HOLD_VIOLATIONS=$(grep "min delay/hold" "${REPORT_DIR}/sta_full_report.log" | grep -c "VIOLATED" 2>/dev/null || echo "0")
    HOLD_VIOLATIONS=$(echo "$HOLD_VIOLATIONS" | tr -d '
' | awk '{print $1}')
  fi
  
  # Extract some cell counts from synthesis if available
  if grep -q "Chip area for top module" "${REPORT_DIR}/sta_full_report.log"; then
    CHIP_AREA=$(grep "Chip area for top module" "${REPORT_DIR}/sta_full_report.log" | awk '{print $NF}')
  else
    CHIP_AREA="N/A"
  fi
  
  # Extract clock skew information
  if [ -f "${REPORT_DIR}/sta_clock_skew.txt" ]; then
    CLOCK_SKEW=$(grep -m 1 -A 3 "Clock" "${REPORT_DIR}/sta_clock_skew.txt" | tail -1 | awk '{print $NF}')
  else
    # Look for the setup skew line in the log file
    CLOCK_SKEW=$(grep -A 6 "CLOCK SKEW" "${REPORT_DIR}/sta_full_report.log" | grep "setup skew" | awk '{print $NF}')
  fi
  
  # Extract critical paths and endpoints
  if [ -f "${REPORT_DIR}/sta_report_max.txt" ]; then
    # Extract first critical path details
    CRITICAL_PATH_START=$(grep -m 1 "Startpoint:" "${REPORT_DIR}/sta_report_max.txt" | cut -d':' -f2- | xargs)
    CRITICAL_PATH_END=$(grep -m 1 "Endpoint:" "${REPORT_DIR}/sta_report_max.txt" | cut -d':' -f2- | xargs)
    MAX_PATHS=$(grep -m 1 -A 20 "Startpoint:" "${REPORT_DIR}/sta_report_max.txt" 2>/dev/null | head -20)
  else
    # Try to extract from the log file
    CRITICAL_PATH_START=$(grep -m 1 "Startpoint:" "${REPORT_DIR}/sta_full_report.log" | cut -d':' -f2- | xargs)
    CRITICAL_PATH_END=$(grep -m 1 "Endpoint:" "${REPORT_DIR}/sta_full_report.log" | cut -d':' -f2- | xargs)
    MAX_PATHS=$(grep -m 1 -A 20 "Startpoint:" "${REPORT_DIR}/sta_full_report.log" 2>/dev/null | head -20)
  fi
  
  if [ -z "$CRITICAL_PATH_START" ]; then
    CRITICAL_PATH_START="Not found"
  fi
  
  if [ -z "$CRITICAL_PATH_END" ]; then
    CRITICAL_PATH_END="Not found"
  fi
  
  # Determine overall timing status
  if [ -z "$WORST_SLACK_SETUP" ] && [ -z "$WORST_SLACK_HOLD" ]; then
    STATUS="TIMING ANALYSIS INCONCLUSIVE"
    STATUS_MSG="Timing analysis was run but complete data could not be extracted from logs."
  elif [ -n "$WORST_SLACK_SETUP" ] && [ $(echo "$WORST_SLACK_SETUP < 0" | bc -l) -eq 1 ] || [ -n "$WORST_SLACK_HOLD" ] && [ $(echo "$WORST_SLACK_HOLD < 0" | bc -l) -eq 1 ]; then
    STATUS="TIMING VIOLATIONS DETECTED"
    STATUS_MSG="Design has $SETUP_VIOLATIONS setup violations and $HOLD_VIOLATIONS hold violations.
Worst setup slack: ${WORST_SLACK_SETUP:-N/A} ns
Worst hold slack: ${WORST_SLACK_HOLD:-N/A} ns"
  else
    STATUS="TIMING MET"
    STATUS_MSG="Design meets timing constraints.
Setup slack: ${WORST_SLACK_SETUP:-N/A} ns
Hold slack: ${WORST_SLACK_HOLD:-N/A} ns"
  fi
  
  # Create a new YAML file with detailed timing information
  TMP_YAML="${REPORT_DIR}/temp_timing.yaml"
  
  cat > "${TMP_YAML}" << EOL
---
# Timing Analysis Summary
# Generated: $(date)
# Design: ${TOP_MODULE}

status: "${STATUS}"

message: |
  ${STATUS_MSG}

design_info:
  top_module: ${TOP_MODULE}
  netlist: ${SYNTH_DIR}/${TOP_MODULE}_synth.v
  chip_area: "${CHIP_AREA}"

timing_constraints:
  clock_period: "${CLOCK_PERIOD} ns"
  clocks: "${CLOCKS}"

timing_summary:
  worst_setup_slack: "${WORST_SLACK_SETUP:-N/A} ns"
  worst_hold_slack: "${WORST_SLACK_HOLD:-N/A} ns"
  total_negative_slack: "${TNS:-N/A} ns"
  worst_negative_slack: "${WNS:-N/A} ns"
  setup_violations: "${SETUP_VIOLATIONS}"
  hold_violations: "${HOLD_VIOLATIONS}"
  clock_skew: "${CLOCK_SKEW:-N/A} ns"

critical_path:
  startpoint: "${CRITICAL_PATH_START}"
  endpoint: "${CRITICAL_PATH_END}"
  details: |
$(echo "${MAX_PATHS}" | sed 's/^/    /')

reports:
  # Standard Timing Analysis reports
  - name: "Full STA Log"
    file: "sta_full_report.log"
    description: "Complete log output from OpenSTA timing analysis run"
    
  - name: "Maximum Delay Paths"
    file: "sta_report_max.txt"
    description: "Detailed report of worst-case (setup) timing paths"
    
  - name: "Minimum Delay Paths"
    file: "sta_report_min.txt"
    description: "Detailed report of best-case (hold) timing paths"
    
  - name: "Clock Skew Report"
    file: "sta_clock_skew.txt"
    description: "Report of clock skew between timing paths"

commands:
  run_sta: "make sta"
  run_sta_background: "make sta_background"
  generate_sdf: "make generate_sdf"
  view_report: "make timing_report"
  view_summary: "make timing_summary"
EOL
  
  # Replace the original file
  mv "${TMP_YAML}" "${SUMMARY_YAML}"
  
  echo "Timing data extracted and summarized in ${SUMMARY_YAML}"
else
  # Add explanatory message if no reports exist
  cat > "${SUMMARY_YAML}" << EOL
---
# Timing Analysis Summary (NOT YET GENERATED)
# Generated: $(date)
# Design: ${TOP_MODULE}

status: "NO TIMING DATA AVAILABLE"

message: |
  No timing analysis has been run yet. To generate timing data, run:
    make sta               # Run timing analysis
  
  After running timing analysis, this file will be updated with
  actual slack values, timing paths, and violation information.

design_info:
  top_module: ${TOP_MODULE}
  netlist: ${SYNTH_DIR}/${TOP_MODULE}_synth.v

commands:
  run_sta: "make sta"
  run_sta_background: "make sta_background"
  generate_sdf: "make generate_sdf"
  estimate_constraints: "make estimate_constraints"
  view_report: "make timing_report"
  view_summary: "make timing_summary"
EOL
  echo "No timing analysis reports found. Run 'make sta' first."
fi

echo "Timing summary YAML created at ${SUMMARY_YAML}"
