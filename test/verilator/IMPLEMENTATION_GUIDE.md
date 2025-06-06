# NoC Router Verilator Testbench Implementation Guide

This guide explains how to adapt the Verilator testbench to work with the actual signals in your generated Verilog code. Since Bluespec generates Verilog with specific naming conventions, you'll need to update the testbench to match these signal names.

## Understanding BSV to Verilog Signal Mapping

When Bluespec compiles your BSV code to Verilog, it follows specific naming conventions for methods and interfaces:

### Method Action Signals

For each `method Action` in your BSV interface, Verilator will expose:
- `<method_name>_EN`: Enable signal (1 when method is called)
- Parameters as individual signals: `<method_name>_<param_name>`

### Method ActionValue Signals

For each `method ActionValue` in your BSV interface, Verilator will expose:
- `<method_name>_EN`: Enable signal (1 when method is called)
- `<method_name>_RDY`: Ready signal (1 when method can be called)
- `<method_name>`: Return value signal

## Updating the Testbench

### Step 1: Generate Verilog and Inspect Signal Names

First, generate the Verilog code:

```bash
make generate_verilog
```

Then examine the generated Verilog file to identify the signal names:

```bash
less build/rtl/verilog/mk_router.v
```

### Step 2: Update the `sendPacket()` Method

Based on your router interface, you'll need to update the `sendPacket()` method in the testbench. Here's an example of how it might look:

```cpp
void sendPacket(int vcNum, const RouterPacket& packet) {
    std::cout << "Sending packet to VC" << vcNum << ": ";
    print_packet("", packet);
    
    // Reset all enable signals
    m_router->queue_data_vc1_EN = 0;
    m_router->queue_data_vc2_EN = 0;
    m_router->queue_data_vc3_EN = 0;
    m_router->queue_data_vc4_EN = 0;
    
    // Set packet data based on VC number
    switch (vcNum) {
        case 1:
            m_router->queue_data_vc1_router_id_x = packet.router_id_x;
            m_router->queue_data_vc1_router_id_y = packet.router_id_y;
            m_router->queue_data_vc1_payload = packet.payload;
            m_router->queue_data_vc1_EN = 1;
            break;
        case 2:
            m_router->queue_data_vc2_router_id_x = packet.router_id_x;
            m_router->queue_data_vc2_router_id_y = packet.router_id_y;
            m_router->queue_data_vc2_payload = packet.payload;
            m_router->queue_data_vc2_EN = 1;
            break;
        case 3:
            m_router->queue_data_vc3_router_id_x = packet.router_id_x;
            m_router->queue_data_vc3_router_id_y = packet.router_id_y;
            m_router->queue_data_vc3_payload = packet.payload;
            m_router->queue_data_vc3_EN = 1;
            break;
        case 4:
            m_router->queue_data_vc4_router_id_x = packet.router_id_x;
            m_router->queue_data_vc4_router_id_y = packet.router_id_y;
            m_router->queue_data_vc4_payload = packet.payload;
            m_router->queue_data_vc4_EN = 1;
            break;
    }
    
    // Tick once to process the input
    tick();
    
    // Reset enable signals
    m_router->queue_data_vc1_EN = 0;
    m_router->queue_data_vc2_EN = 0;
    m_router->queue_data_vc3_EN = 0;
    m_router->queue_data_vc4_EN = 0;
    
    // Run for a few cycles to let the packet propagate
    for (int i = 0; i < 5; i++) {
        tick();
    }
    
    // Predict routing direction
    Direction expectedDir = determine_route(packet, m_currentX, m_currentY);
    std::cout << "  Expected direction: ";
    switch (expectedDir) {
        case NORTH: std::cout << "NORTH"; break;
        case SOUTH: std::cout << "SOUTH"; break;
        case EAST: std::cout << "EAST"; break;
        case WEST: std::cout << "WEST"; break;
        case PE: std::cout << "PE (Local)"; break;
    }
    std::cout << std::endl;
}
```

### Step 3: Update the `checkOutputs()` Method

Similarly, update the `checkOutputs()` method to read from the router output signals:

```cpp
void checkOutputs() {
    std::cout << "Checking router outputs at tick " << m_tickCount << std::endl;
    
    // Check North output
    RouterPacket northPacket(
        m_router->router_out_north_router_id_x,
        m_router->router_out_north_router_id_y,
        m_router->router_out_north_payload
    );
    print_packet("North output", northPacket);
    
    // Check South output
    RouterPacket southPacket(
        m_router->router_out_south_router_id_x,
        m_router->router_out_south_router_id_y,
        m_router->router_out_south_payload
    );
    print_packet("South output", southPacket);
    
    // Check East output
    RouterPacket eastPacket(
        m_router->router_out_east_router_id_x,
        m_router->router_out_east_router_id_y,
        m_router->router_out_east_payload
    );
    print_packet("East output", eastPacket);
    
    // Check West output
    RouterPacket westPacket(
        m_router->router_out_west_router_id_x,
        m_router->router_out_west_router_id_y,
        m_router->router_out_west_payload
    );
    print_packet("West output", westPacket);
}
```

## Handling Reset and Clock

The BSV-generated Verilog typically has specific signal names for reset and clock:

```cpp
// In the constructor
RouterTestbench(uint8_t x, uint8_t y) : m_tickCount(0), m_currentX(x), m_currentY(y) {
    // Initialize Verilator
    Verilated::traceEverOn(true);
    
    // Create instance of module
    m_router = new Vmk_router;
    
    // Create trace file
    m_trace = new VerilatedVcdC;
    m_router->trace(m_trace, 99);
    m_trace->open("router_trace.vcd");
    
    // Initial reset
    m_router->RST_N = 0;  // Active low reset
    for (int i = 0; i < 10; i++) {
        tick();
    }
    m_router->RST_N = 1;  // Release reset
}

// In the tick method
void tick() {
    // Toggle clock
    m_router->CLK = 0;
    m_router->eval();
    m_trace->dump(m_tickCount * 2);
    
    m_router->CLK = 1;
    m_router->eval();
    m_trace->dump(m_tickCount * 2 + 1);
    
    m_tickCount++;
}
```

## Testing Multiple Connected Routers

To test multiple connected routers (like your 2x2 mesh), you'll need to:

1. Create multiple router instances
2. Connect their input/output signals
3. Drive packets to one router and observe propagation

Here's a simplified example:

```cpp
class MultiRouterTestbench {
private:
    Vmk_router* m_router00;
    Vmk_router* m_router01;
    Vmk_router* m_router10;
    Vmk_router* m_router11;
    // ... other members ...

public:
    MultiRouterTestbench() {
        // Create router instances
        m_router00 = new Vmk_router;
        m_router01 = new Vmk_router;
        m_router10 = new Vmk_router;
        m_router11 = new Vmk_router;
        
        // ... initialization code ...
    }
    
    void tick() {
        // Toggle clock for all routers
        m_router00->CLK = 0;
        m_router01->CLK = 0;
        m_router10->CLK = 0;
        m_router11->CLK = 0;
        
        // Evaluate all routers
        m_router00->eval();
        m_router01->eval();
        m_router10->eval();
        m_router11->eval();
        
        // ... dump trace ...
        
        // Connect router outputs to inputs
        // For example: router00's north output connects to router01's south input
        connectRouters();
        
        // Toggle clock high
        m_router00->CLK = 1;
        m_router01->CLK = 1;
        m_router10->CLK = 1;
        m_router11->CLK = 1;
        
        // ... evaluate and dump trace again ...
    }
    
    void connectRouters() {
        // Example: Connect router00's north output to router01's south input
        m_router01->queue_data_vc1_router_id_x = m_router00->router_out_north_router_id_x;
        m_router01->queue_data_vc1_router_id_y = m_router00->router_out_north_router_id_y;
        m_router01->queue_data_vc1_payload = m_router00->router_out_north_payload;
        m_router01->queue_data_vc1_EN = 1; // Only set if there's valid data
        
        // ... other connections ...
    }
    
    // ... other methods ...
};
```

## Debugging Tips

1. **Use VCD Traces**: The testbench generates a VCD file that you can view with GTKWave to see signal transitions.

2. **Add Debug Prints**: Add print statements to track packet flow through the router.

3. **Check Signal Values**: Print the values of key signals to verify they match expected values.

4. **Isolate Issues**: Test one feature at a time to isolate problems.

5. **Verify Routing Logic**: Compare the expected routing direction with the actual output direction.

## Next Steps

1. Generate the Verilog code
2. Examine the signal names in the generated Verilog
3. Update the testbench with the correct signal names
4. Run the testbench and debug any issues
5. Extend the testbench to test more complex scenarios
