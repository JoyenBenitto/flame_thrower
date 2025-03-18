#!/bin/bash

# Script to generate a consolidated YAML report with synthesis and timing data

# Set up the environment
SYNTH_DIR="./build/synth"
REPORT_DIR="${SYNTH_DIR}/reports"
REPORT_YAML="${REPORT_DIR}/design_report.yaml"
TOP_MODULE="mk_router"

# Make sure the report directory exists
mkdir -p "${REPORT_DIR}"

# Initialize YAML file
cat > "${REPORT_YAML}" << EOL
---
# Consolidated Design Report
# Generated: $(date)

design_info:
  top_module: ${TOP_MODULE}
  netlist: ${SYNTH_DIR}/${TOP_MODULE}_synth.v
  sdf_file: ${SYNTH_DIR}/${TOP_MODULE}.sdf
  sdc_file: ${SYNTH_DIR}/${TOP_MODULE}.sdc

# Synthesis information will be added here
synthesis_report:
  
# Timing information will be added here
timing_report:
  
# Available reports
reports:
  - category: "Synthesis"
    files:
      - name: "Synthesis Log"
        path: "${SYNTH_DIR}/synth.log"
        description: "Full synthesis log from Yosys"
  
  - category: "Timing"
    files:
      - name: "Full STA Log"
        path: "${REPORT_DIR}/sta_full_report.log"
        description: "Complete log from OpenSTA timing analysis"
      
      - name: "Maximum Delay Paths"
        path: "${REPORT_DIR}/sta_report_max.txt"
        description: "Worst-case (setup) timing paths"
      
      - name: "Minimum Delay Paths"
        path: "${REPORT_DIR}/sta_report_min.txt"
        description: "Best-case (hold) timing paths"
      
      - name: "Clock Skew Report"
        path: "${REPORT_DIR}/sta_clock_skew.txt"
        description: "Clock skew between timing paths"
      
      - name: "Constraint Estimation"
        path: "${REPORT_DIR}/constraint_estimation.log"
        description: "Generated timing constraints"
      
      - name: "SDF Generation Log"
        path: "${REPORT_DIR}/sdf_generation.log"
        description: "SDF file generation log"

# Commands
commands:
  synth: "make synth"
  timing: "make timing"
  report: "make report"
EOL

# Extract synthesis data if available
if [ -f "${SYNTH_DIR}/synth.log" ]; then
  echo "Extracting synthesis data..."
  
  # Get cell usage
  CELL_COUNT=$(grep -A 20 "Cell usage statistics" "${SYNTH_DIR}/synth.log" 2>/dev/null | grep -v "Cell usage statistics" | head -10)
  
  # Get warnings if any
  WARNING_COUNT=$(grep -c "Warning" "${SYNTH_DIR}/synth.log" 2>/dev/null || echo "0")
  
  # Insert synthesis data into YAML
  TMP_YAML="${REPORT_DIR}/temp_report.yaml"
  
  sed -n '1,/synthesis_report:/p' "${REPORT_YAML}" > "${TMP_YAML}"
  
  cat >> "${TMP_YAML}" << EOL
  status: "Synthesis completed"
  cell_usage: |
$(echo "${CELL_COUNT}" | sed 's/^/    /')
  
  warnings: ${WARNING_COUNT}
  timestamp: "$(grep "Synthesis completed" "${SYNTH_DIR}/synth.log" | head -1 | sed 's/^.*Synthesis completed//g' || echo "Unknown")"
EOL
  
  # Copy the rest of the file after synthesis_report section
  sed -n '/# Timing information/,$p' "${REPORT_YAML}" >> "${TMP_YAML}"
  
  # Replace the original file
  mv "${TMP_YAML}" "${REPORT_YAML}"
  
  echo "Synthesis data extracted."
else
  # Update the synthesis section with status
  sed -i "/synthesis_report:/a\  status: \"Not run yet - use 'make synth'\"" "${REPORT_YAML}"
  echo "No synthesis log found. Run 'make synth' first."
fi

# Extract timing data if available
echo "Checking for timing data in ${REPORT_DIR}/sta_full_report.log..."
if [ -f "${REPORT_DIR}/timing_summary.yaml" ]; then
  echo "Using data from timing summary YAML file"
  TIMING_DATA_AVAILABLE=true
elif [ -f "${REPORT_DIR}/sta_full_report.log" ] && grep -q "slack" "${REPORT_DIR}/sta_full_report.log" 2>/dev/null; then
  echo "Extracting timing data..."
  
  # Extract worst slack (setup time)
  WORST_SLACK=$(grep -A 3 "Worst slack" "${REPORT_DIR}/sta_full_report.log" | grep "slack" | head -1 | awk '{print $NF}')
  
  # Extract total negative slack if present
  TNS=$(grep "TNS" "${REPORT_DIR}/sta_full_report.log" | grep -v "TNSF" | head -1 | awk '{print $NF}')
  
  # Extract worst hold time if available
  WORST_HOLD=$(grep -A 3 "min delay" "${REPORT_DIR}/sta_full_report.log" | grep "slack" | head -1 | awk '{print $NF}')
  
  # Extract clocks if available
  CLOCKS=$(grep "Clock" "${REPORT_DIR}/sta_full_report.log" | grep "Period" | awk '{print $2}' | sort -u | tr '\n' ' ')
  
  # Count the number of timing violations if any
  SETUP_VIOLATIONS=$(grep -c "VIOLATED" "${REPORT_DIR}/sta_report_max.txt" 2>/dev/null || echo "0")
  HOLD_VIOLATIONS=$(grep -c "VIOLATED" "${REPORT_DIR}/sta_report_min.txt" 2>/dev/null || echo "0")
  
  # Extract timing path information
  MAX_PATHS=$(grep -A 20 "Startpoint" "${REPORT_DIR}/sta_report_max.txt" | head -20)
  MIN_PATHS=$(grep -A 20 "Startpoint" "${REPORT_DIR}/sta_report_min.txt" | head -20)
  
  # Insert timing data into YAML
  TMP_YAML="${REPORT_DIR}/temp_report.yaml"
  
  # Find where the timing_report section starts and ends
  START_LINE=$(grep -n "timing_report:" "${REPORT_YAML}" | cut -d ':' -f 1)
  END_LINE=$(grep -n "# Available reports" "${REPORT_YAML}" | cut -d ':' -f 1)
  
  # Copy the file up to timing_report section
  head -n "${START_LINE}" "${REPORT_YAML}" > "${TMP_YAML}"
  
  # Add the timing data
  cat >> "${TMP_YAML}" << EOL
timing_report:
  status: "Timing analysis completed"
  worst_setup_slack: ${WORST_SLACK:-"N/A"}
  total_negative_slack: ${TNS:-"N/A"}
  worst_hold_slack: ${WORST_HOLD:-"N/A"}
  setup_violations: ${SETUP_VIOLATIONS}
  hold_violations: ${HOLD_VIOLATIONS}
  clocks: "${CLOCKS}"
  
  # Critical paths (setup)
  critical_setup_paths: |
$(echo "${MAX_PATHS}" | sed 's/^/    /')
  
  # Critical paths (hold)
  critical_hold_paths: |
$(echo "${MIN_PATHS}" | sed 's/^/    /')
  
  timing_status: |
    ${SETUP_VIOLATIONS} setup violations, ${HOLD_VIOLATIONS} hold violations
    Worst setup slack: ${WORST_SLACK:-"N/A"}
    Worst hold slack: ${WORST_HOLD:-"N/A"}
    Total Negative Slack: ${TNS:-"N/A"}
EOL
  
  # Add the rest of the file after the timing_report section
  tail -n +"${END_LINE}" "${REPORT_YAML}" >> "${TMP_YAML}"
  
  # Replace the original file
  mv "${TMP_YAML}" "${REPORT_YAML}"
  
    echo "Timing data extracted from sta_full_report.log."
elif [ -f "${REPORT_DIR}/timing_summary.yaml" ]; then
  echo "Using timing summary data from ${REPORT_DIR}/timing_summary.yaml"
  
  # Copy the timing summary data into the main report
  TMP_YAML="${REPORT_DIR}/temp_report.yaml"
  START_LINE=$(grep -n "timing_report:" "${REPORT_YAML}" | cut -d ':' -f 1)
  END_LINE=$(grep -n "# Available reports" "${REPORT_YAML}" | cut -d ':' -f 1)

  # Copy the file up to timing_report section
  head -n "${START_LINE}" "${REPORT_YAML}" > "${TMP_YAML}"
  
  # Add timing data from timing_summary.yaml
  echo "timing_report:" >> "${TMP_YAML}"
  sed -n '2,$p' "${REPORT_DIR}/timing_summary.yaml" | sed 's/^/  /' >> "${TMP_YAML}"
  
  # Add the rest of the file after the timing_report section
  tail -n +"${END_LINE}" "${REPORT_YAML}" >> "${TMP_YAML}"
  
  # Replace the original file
  mv "${TMP_YAML}" "${REPORT_YAML}"
  
  echo "Timing data extracted from timing_summary.yaml."
else
  # Update the timing section with status if not already added
  if ! grep -q "status:" "${REPORT_YAML}" | grep -A 1 "timing_report:"; then
    sed -i "/timing_report:/a\  status: \"Not run yet - use 'make timing'\"" "${REPORT_YAML}"
  fi
  echo "No timing analysis reports found. Run 'make timing' first."
fi

echo "Consolidated report generated at ${REPORT_YAML}"
