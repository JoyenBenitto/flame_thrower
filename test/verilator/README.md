# NoC Router Verilator Testbench

This directory contains a Verilator-based testbench for the Network-on-Chip (NoC) router. The testbench allows you to simulate and test the router's functionality using Verilator, which provides faster simulation speeds compared to traditional HDL simulators.

## Overview

The testbench is designed to:

1. Create a router instance at a specified position (X,Y)
2. Send test packets to different virtual channels
3. Monitor the router outputs
4. Verify the routing behavior based on the XY routing algorithm

## Files

- `tb_router_verilator.cpp`: The main testbench file that creates a router instance and sends test packets
- `router_trace.vcd`: Generated VCD trace file for waveform viewing (created during simulation)

## Usage

### Prerequisites

Make sure you have Verilator installed:

```bash
sudo apt-get install verilator
```

### Building and Running

The Makefile in the project root directory has been updated with Verilator targets:

1. **Prepare files for Verilator simulation**:
   ```bash
   make verilator_prep
   ```

2. **Build the Verilator simulation**:
   ```bash
   make verilator_build
   ```

3. **Run the Verilator simulation**:
   ```bash
   make verilator_run
   ```

Or run all steps at once:
```bash
make verilator_run
```

### Viewing Waveforms

After running the simulation, you can view the generated waveforms using GTKWave:

```bash
gtkwave build/verilator/router_trace.vcd
```

## Customizing the Testbench

### Adding New Test Packets

To add new test packets, modify the `testPackets` vector in the `main()` function:

```cpp
std::vector<RouterPacket> testPackets = {
    RouterPacket(0, 1, 0x12345678),  // North
    RouterPacket(1, 0, 0x87654321),  // East
    // Add your new packets here
    RouterPacket(1, 1, 0xAABBCCDD),  // Example new packet
};
```

### Modifying Router Position

To test a router at a different position in the mesh, change the constructor parameters:

```cpp
// Create testbench with router at position (1,1)
RouterTestbench tb(1, 1);
```

### Implementing Signal Connections

The current testbench includes placeholder comments for connecting to the actual Verilog signals. Once you've generated the Verilog code and examined the signal names, you'll need to update the `sendPacket()` and `checkOutputs()` methods to use the actual signal names.

## Development Tips

1. Start with simple test cases and gradually add complexity
2. Use the VCD trace file to debug routing issues
3. Compare the expected routing direction with the actual output
4. Modify the testbench to test different aspects of the router (e.g., congestion, arbitration)

## Extending the Testbench

Some ideas for extending the testbench:

1. Add support for multiple connected routers to test a complete NoC
2. Implement traffic generators for more realistic testing
3. Add performance metrics (latency, throughput)
4. Test different routing algorithms (XY vs YX)
