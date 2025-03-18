TOP_DIR=src
TOP_DIR_TB=test
TOP_FILE=router.bsv
TOP_MODULE=mk_router
TOP_FILE_TB=tb_router.bsv
TOP_MODULE_TB=mk_tb_router

BUILD_DIR=./build/rtl
BUILD_IMM=./build/rtl/inter
BUILD_VERILOG=./build/rtl/verilog

SIM_DIR_MST=./build/sim
SIM_DIR=./build/sim/sim_files
SIM_IMM=./build/sim/inter
SIM_BIN=./build/sim/bin
SIM_BIN_NAME=sim_bin

BSC_INCLUDES=-p ./src/:%/Libraries:./test/

.PHONY: generate_verilog
generate_verilog:
	@echo "generating verilog"
	@mkdir -p build $(BUILD_DIR) $(BUILD_IMM) $(BUILD_VERILOG)
	@bsc -u -verilog -vdir $(BUILD_VERILOG) -g $(TOP_MODULE) -bdir $(BUILD_IMM) $(BSC_INCLUDES) $(TOP_DIR)/$(TOP_FILE)

.PHONY: sim
sim:
	@echo "creating a bsv bin for sim"
	@mkdir -p build $(SIM_DIR_MST) $(SIM_DIR) $(SIM_IMM) $(SIM_BIN)
	@bsc -u -sim -g $(TOP_MODULE_TB) -simdir $(SIM_DIR) -bdir $(SIM_IMM) $(BSC_INCLUDES) $(TOP_DIR_TB)/$(TOP_FILE_TB)
	@bsc -u -sim -e $(TOP_MODULE_TB) -simdir $(SIM_DIR) -bdir $(SIM_IMM) -o $(SIM_BIN)/$(SIM_BIN_NAME)
	@./$(SIM_BIN)/$(SIM_BIN_NAME)

.PHONY: compile_test
compile_test:
	@echo "running test"
	@mkdir -p build $(BUILD_DIR) $(BUILD_IMM) $(BUILD_VERILOG)
	@bsc -u -verilog -vdir $(BUILD_VERILOG) -g $(TOP_MODULE_TB) -bdir $(BUILD_IMM) $(BSC_INCLUDES) $(TOP_DIR_TB)/$(TOP_FILE_TB)

.PHONY: clean
clean:
	@rm -rf $(SIM_IMM)/*
	@rm -rf $(SIM_BIN)/*
	@rm -rf $(SIM_DIR)/*.h
	@rm -rf $(SIM_DIR)/*.o
	@rm -rf $(SIM_DIR)/*.cxx
	@rm -rf $(BUILD_IMM)/*bo
	@rm -rf $(BUILD_VERILOG)/*v
	@rm -rf ./build/synth

# Synthesis with Yosys and SkyWater 130nm PDK
SYNTH_DIR=./build/synth
LIB_SKY130_PATH=./OpenROAD-flow-scripts/flow/platforms/sky130hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
BSV_VLIB_DIR=/bluespec/lib/Verilog

# OpenSTA timing analysis setup
OPENSTA_BIN=/home/joyen/Desktop/OpenSTA/app/sta
TIMING_SCRIPTS_DIR=./scripts
SCRIPTS_DIR=./scripts
REPORT_DIR=$(SYNTH_DIR)/reports

.PHONY: generate_synth_verilog
generate_synth_verilog: 
	@echo "Generating synthesizable Verilog"
	@mkdir -p build $(BUILD_DIR) $(BUILD_IMM) $(BUILD_VERILOG)
	@bsc -u -verilog +RTS -K256M -RTS -elab -vdir $(BUILD_VERILOG) -g $(TOP_MODULE) -bdir $(BUILD_IMM) $(BSC_INCLUDES) $(TOP_DIR)/$(TOP_FILE)
	@bsc -u -verilog +RTS -K256M -RTS -vdir $(BUILD_VERILOG) -vsearch $(BSV_VLIB_DIR) -g $(TOP_MODULE) -bdir $(BUILD_IMM) $(BSC_INCLUDES) $(TOP_DIR)/$(TOP_FILE)

.PHONY: synth_prepare
synth_prepare: generate_synth_verilog
	@echo "Preparing files for synthesis with SkyWater 130nm PDK"
	@mkdir -p $(SYNTH_DIR)
	@mkdir -p $(SYNTH_DIR)/lib
	@# Copy all needed Bluespec modules
	@cp /bluespec/lib/Verilog/SizedFIFO*.v $(SYNTH_DIR)/lib/
	@cp /bluespec/lib/Verilog/FIFO*.v $(SYNTH_DIR)/lib/
	@cp /bluespec/lib/Verilog/SyncFIFO*.v $(SYNTH_DIR)/lib/
	@cp /bluespec/lib/Verilog/RevertReg.v $(SYNTH_DIR)/lib/
	@# Create file list with proper ordering (library files first)
	@echo "// Generated file list for synthesis" > $(SYNTH_DIR)/file_list.txt
	@find $(SYNTH_DIR)/lib -name "*.v" | sort >> $(SYNTH_DIR)/file_list.txt
	@find $(BUILD_VERILOG) -name "*.v" | sort >> $(SYNTH_DIR)/file_list.txt
	@# Print the file list for debugging
	@echo "=== Verilog files for synthesis ==="
	@cat $(SYNTH_DIR)/file_list.txt
	@echo "==================================="

.PHONY: synth
synth: synth_prepare
	@echo "Synthesizing with Yosys and SkyWater 130nm PDK"
	@# Create a single combined Verilog file with all modules
	@rm -f $(SYNTH_DIR)/all_modules.v
	@for file in $$(find $(SYNTH_DIR)/lib -name "*.v" | sort); do \
		cat $$file >> $(SYNTH_DIR)/all_modules.v; \
		echo >> $(SYNTH_DIR)/all_modules.v; \
	done
	@cat $(BUILD_VERILOG)/$(TOP_MODULE).v >> $(SYNTH_DIR)/all_modules.v
	@# Run synthesis with directly reading the combined file
	@yosys -p "read_verilog -sv $(SYNTH_DIR)/all_modules.v; \
		hierarchy -check -top $(TOP_MODULE); \
		proc; opt; fsm; opt; memory; opt; \
		techmap; opt; \
		dfflibmap -liberty $(LIB_SKY130_PATH); \
		abc -liberty $(LIB_SKY130_PATH); \
		clean; \
		write_verilog -noattr $(SYNTH_DIR)/$(TOP_MODULE)_synth.v; \
		stat -liberty $(LIB_SKY130_PATH)" | tee $(SYNTH_DIR)/synth.log || (echo "Synthesis failed, see $(SYNTH_DIR)/synth.log for details." && exit 1)
	@echo "Synthesis completed. Results in $(SYNTH_DIR)/$(TOP_MODULE)_synth.v"

.PHONY: synth timing report sdf constraints help

# Main timing analysis target
.PHONY: timing sta sta_background
timing: sta

sta: synth
	@echo "Running timing analysis with OpenSTA"
	@mkdir -p $(REPORT_DIR)
	@export LIB_SKY130_PATH=$(LIB_SKY130_PATH) && \
	export SYNTH_NETLIST=$(SYNTH_DIR)/$(TOP_MODULE)_synth.v && \
	export TOP_MODULE=$(TOP_MODULE) && \
	export SDC_FILE=$(SDC_FILE) && \
	export REPORT_DIR=$(REPORT_DIR) && \
	$(SCRIPTS_DIR)/run_sta.sh
	@echo "Timing analysis completed. Run 'make report' to generate a comprehensive report."

# Background execution version of STA (non-blocking)
sta_background: synth
	@echo "Running timing analysis with OpenSTA in background (non-blocking)"
	@mkdir -p $(REPORT_DIR)
	@export LIB_SKY130_PATH=$(LIB_SKY130_PATH) && \
	export SYNTH_NETLIST=$(SYNTH_DIR)/$(TOP_MODULE)_synth.v && \
	export TOP_MODULE=$(TOP_MODULE) && \
	export SDC_FILE=$(SDC_FILE) && \
	export REPORT_DIR=$(REPORT_DIR) && \
	$(SCRIPTS_DIR)/run_sta.sh &
	@echo "Timing analysis launched in background. Check $(REPORT_DIR)/sta_full_report.log for progress."

# Generate a consolidated YAML report with synthesis and timing data
report:
	@echo "Generating consolidated synthesis and timing report..."
	@./scripts/generate_report.sh
	@echo "Report available at $(REPORT_DIR)/design_report.yaml"
	@echo ""
	@echo "Quick summary:"
	@if [ -f "$(REPORT_DIR)/design_report.yaml" ]; then \
		grep -A 3 "worst_setup_slack:" $(REPORT_DIR)/design_report.yaml | head -4; \
		echo "For full details, view the report with 'cat $(REPORT_DIR)/design_report.yaml'"; \
	fi



.PHONY: sdf
sdf: timing
	@echo "Generating SDF file for $(TOP_MODULE)"
	@mkdir -p $(REPORT_DIR)
	@export LIB_SKY130_PATH=$(LIB_SKY130_PATH) && \
	export SYNTH_NETLIST=$(SYNTH_DIR)/$(TOP_MODULE)_synth.v && \
	export TOP_MODULE=$(TOP_MODULE) && \
	export SDC_FILE=$(SDC_FILE) && \
	export SDF_OUTPUT=$(SYNTH_DIR)/$(TOP_MODULE).sdf && \
	timeout 300s $(OPENSTA_BIN) $(SCRIPTS_DIR)/sta_wrapper.tcl $(SCRIPTS_DIR)/generate_sdf.tcl | tee $(REPORT_DIR)/sdf_generation.log
	@echo "SDF generation completed. Results in $(SYNTH_DIR)/$(TOP_MODULE).sdf"
	@echo "Run 'make report' to update the consolidated report with this information."

# Simplified targets that redirect to proper commands
.PHONY: generate_sdf estimate_constraints timing_report

generate_sdf:
	@echo "'generate_sdf' is deprecated, use 'make sdf' instead"
	@make sdf

timing_report:
	@echo "'timing_report' is deprecated, use 'make report' instead"
	@make report

.PHONY: constraints
constraints: timing
	@echo "Estimating timing constraints for $(TOP_MODULE)"
	@mkdir -p $(REPORT_DIR)
	@export LIB_SKY130_PATH=$(LIB_SKY130_PATH) && \
	export SYNTH_NETLIST=$(SYNTH_DIR)/$(TOP_MODULE)_synth.v && \
	export TOP_MODULE=$(TOP_MODULE) && \
	timeout 300s $(OPENSTA_BIN) $(SCRIPTS_DIR)/sta_wrapper.tcl $(SCRIPTS_DIR)/estimate_constraints.tcl | tee $(REPORT_DIR)/constraint_estimation.log
	@echo "Constraint estimation completed. Results in $(REPORT_DIR)/constraint_estimation.log"
	@echo "You can use these as a starting point for creating an SDC file."
	@echo "Run 'make report' to update the consolidated report with this information."

estimate_constraints:
	@echo "'estimate_constraints' is deprecated, use 'make constraints' instead"
	@make constraints

# Show help for available commands
.PHONY: help
help:
	@echo "Available Commands:"
	@echo "  make synth         - Run synthesis"
	@echo "  make timing       - Run timing analysis"
	@echo "  make sdf          - Generate SDF file for simulation"
	@echo "  make constraints  - Estimate timing constraints"
	@echo "  make report       - Generate comprehensive report"
	@echo "  make help         - Show this help"
	@echo ""
	@echo "Flow: 1) synth → 2) timing → 3) report"
