TOP_DIR=src
TOP_FILE=buffer.bsv
TOP_MODULE= mkBuffer

BUILD_DIR= ./build/rtl
BUILD_IMM= ./build/rtl/inter
BUILD_VERILOG= ./build/rtl/verilog

SIM_DIR_MST= ./build/sim
SIM_DIR= ./build/sim/sim_files
SIM_IMM= ./build/sim/inter
SIM_BIN= ./build/sim/bin
SIM_BIN_NAME= sim_bin

.PHONY: generate_verilog
generate_verilog:
	@echo "generating verilog"
	@mkdir -p build $(BUILD_DIR) $(BUILD_IMM) $(BUILD_VERILOG)
	@bsc -verilog -vdir $(BUILD_VERILOG) -bdir $(BUILD_IMM) $(TOP_DIR)/$(TOP_FILE)

.PHONY: sim
sim:
	@echo "creating a bsv bin for sim"
	@mkdir -p build $(SIM_DIR_MST) $(SIM_DIR) $(SIM_IMM) $(SIM_BIN)
	@bsc -sim -g $(TOP_MODULE) -bdir $(SIM_IMM) $(TOP_DIR)/$(TOP_FILE)
	@bsc -sim -e $(TOP_MODULE) -simdir $(SIM_DIR) -bdir $(SIM_IMM) -o $(SIM_BIN)/$(SIM_BIN_NAME)
	@./$(SIM_BIN)/$(SIM_BIN_NAME)

.PHONY: clean
clean:
	@rm -rf $(SIM_IMM)/*
	@rm -rf $(SIM_BIN)/*
	@rm -rf $(SIM_DIR)/*.h
	@rm -rf $(SIM_DIR)/*.o
	@rm -rf $(SIM_DIR)/*.cxx
