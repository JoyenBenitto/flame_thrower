TOP_DIR=new_src
TOP_DIR_TB=test
TOP_FILE=tb_router.bsv
TOP_MODULE=mk_tb_router

BUILD_DIR=./build/rtl
BUILD_IMM=./build/rtl/inter
BUILD_VERILOG=./build/rtl/verilog

VERILATOR_DIR=./build/verilator
VERILATOR_TOP=mk_tb_router
VERILATOR_CPP=./sim/sim_main.cpp
VERILATOR_OBJ=$(VERILATOR_DIR)/obj_dir

BSC_INCLUDES=-p ./new_src/:%/Libraries

.PHONY: generate_verilog
generate_verilog:
	@echo "Generating Verilog from BSV..."
	@mkdir -p build $(BUILD_DIR) $(BUILD_IMM) $(BUILD_VERILOG)
	@bsc -u -verilog -vdir $(BUILD_VERILOG) -g $(TOP_MODULE) -bdir $(BUILD_IMM) $(BSC_INCLUDES) $(TOP_DIR)/$(TOP_FILE)

.PHONY: verilator_prep
verilator_prep:
	@echo "Preparing Verilator simulation..."
	@mkdir -p $(VERILATOR_DIR)
	@cp $(BUILD_VERILOG)/*.v $(VERILATOR_DIR)/
	@cp $(VERILATOR_CPP) $(VERILATOR_DIR)/

.PHONY: verilator_build
verilator_build: verilator_prep
	@echo "Building Verilator model..."
	cd $(VERILATOR_DIR) && \
	verilator -cc $(VERILATOR_TOP).v -Wno-fatal --no-timing --exe $(notdir $(VERILATOR_CPP)) \
	-I/bluespec/lib/Verilog -I/bluespec/lib/Verilog.Vivado \
	--top-module $(VERILATOR_TOP) --trace && \
	make -C obj_dir -f V$(VERILATOR_TOP).mk V$(VERILATOR_TOP)

.PHONY: verilator_run
verilator_run:
	@echo "Running Verilator simulation..."
	@cd $(VERILATOR_OBJ) && ./V$(VERILATOR_TOP)

.PHONY: clean
clean:
	@echo "Cleaning all build artifacts..."
	@rm -rf $(BUILD_IMM) $(BUILD_VERILOG)
	@rm -rf $(VERILATOR_DIR)

.PHONY: verilator
verilator: generate_verilog verilator_build verilator_run
	@echo "Completed full Verilator workflow"

.PHONY: help
help:
	@echo "Available Commands:"
	@echo "  make generate_verilog   - Generate Verilog from BSV"
	@echo "  make verilator_prep     - Copy and prep files for Verilator"
	@echo "  make verilator_build    - Compile Verilator simulation"
	@echo "  make verilator_run      - Run Verilator simulation"
	@echo "  make verilator          - Run complete Verilator workflow (generate, build, run)"
	@echo "  make clean              - Clean all build files"
	@echo "  make help               - Show this help"
