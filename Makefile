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

# Verilator directories
VERILATOR_DIR=./build/verilator
VERILATOR_OBJ=./build/verilator/obj_dir
VERILATOR_TB=./test/verilator

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

# Verilator targets
.PHONY: verilator_prep verilator_build verilator_run

verilator_prep: generate_verilog
	@echo "Preparing files for Verilator simulation"
	@mkdir -p $(VERILATOR_DIR) $(VERILATOR_OBJ)
	@# Copy all needed Bluespec modules
	@mkdir -p $(VERILATOR_DIR)/lib
	@cp /bluespec/lib/Verilog/SizedFIFO*.v $(VERILATOR_DIR)/lib/ 2>/dev/null || true
	@cp /bluespec/lib/Verilog/FIFO*.v $(VERILATOR_DIR)/lib/ 2>/dev/null || true
	@cp /bluespec/lib/Verilog/SyncFIFO*.v $(VERILATOR_DIR)/lib/ 2>/dev/null || true
	@cp /bluespec/lib/Verilog/RevertReg.v $(VERILATOR_DIR)/lib/ 2>/dev/null || true
	@# Copy the generated Verilog files
	@cp $(BUILD_VERILOG)/$(TOP_MODULE).v $(VERILATOR_DIR)/
	@echo "Verilator preparation completed"

verilator_build: verilator_prep
	@echo "Building Verilator simulation"
	@cp $(VERILATOR_TB)/tb_router_verilator.cpp $(VERILATOR_DIR)/
	@cd $(VERILATOR_DIR) && verilator -Wall -Wno-UNUSED -Wno-UNDRIVEN -Wno-PINCONNECTEMPTY -Wno-STMTDLY -Wno-CASEINCOMPLETE -Wno-BLKSEQ \
		--trace --no-timing -cc $(TOP_MODULE).v --top-module $(TOP_MODULE) -Ilib \
		--exe tb_router_verilator.cpp
	@cd $(VERILATOR_DIR)/obj_dir && make -f V$(TOP_MODULE).mk
	@echo "Verilator build completed"

verilator_run: verilator_build
	@echo "Running Verilator simulation"
	@cd $(VERILATOR_DIR)/obj_dir && ./V$(TOP_MODULE)
	@echo "Verilator simulation completed"


.PHONY: clean
clean:
	@rm -rf $(SIM_IMM)/*
	@rm -rf $(SIM_BIN)/*
	@rm -rf $(SIM_DIR)/*.h
	@rm -rf $(SIM_DIR)/*.o
	@rm -rf $(SIM_DIR)/*.cxx
	@rm -rf $(BUILD_IMM)/*bo
	@rm -rf $(BUILD_VERILOG)/*v
	@rm -rf $(VERILATOR_OBJ)

# Show help for available commands
.PHONY: help
help:
	@echo "Available Commands:"
	@echo "  make verilator_prep - Prepare files for Verilator simulation"
	@echo "  make verilator_build - Build Verilator simulation"
	@echo "  make verilator_run - Run Verilator simulation"
	@echo "  make help          - Show this help"
