#include "Vmk_tb_router.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    
    // Initialize Verilator
    const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};
    Vmk_tb_router* top = new Vmk_tb_router{contextp.get()};
    
    // Initialize VCD trace file
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);  // Trace 99 levels of hierarchy
    tfp->open("sim_output.vcd");
    
    // Clock and reset
    vluint64_t main_time = 0;
    bool clk = 0;

    // Apply reset
    top->RST_N = 0;
    top->CLK = clk;
    top->eval();
    tfp->dump(main_time);

    for (int i = 0; i < 5; ++i) {
        main_time++;
        clk = !clk;
        top->CLK = clk;
        top->eval();
        tfp->dump(main_time);
    }

    top->RST_N = 1; // Release reset

    // Run simulation
    for (int i = 0; i < 20; ++i) {
        main_time++;
        clk = !clk;
        top->CLK = clk;
        top->eval();
        tfp->dump(main_time);
    }

    // Clean up
    tfp->close();
    delete tfp;
    delete top;
    return 0;
}
