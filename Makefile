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
