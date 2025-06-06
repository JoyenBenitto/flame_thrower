#include "Vmk_router.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <cstdint>
#include <vector>
#include <string>
#include <iomanip>
#include <bitset>

// Direction enum matching the BSV code
enum Direction {
    NORTH = 0,
    SOUTH = 1,
    EAST = 2,
    WEST = 3,
    PE = 4
};

// Packet structure matching the BSV Router_core_packet
struct RouterPacket {
    uint8_t router_id_x;  // 2 bits in BSV
    uint8_t router_id_y;  // 2 bits in BSV
    uint32_t payload;     // 32 bits in BSV
    
    RouterPacket(uint8_t x, uint8_t y, uint32_t p) : router_id_x(x), router_id_y(y), payload(p) {}
};

// Helper function to print packet information
void print_packet(const std::string& prefix, const RouterPacket& packet) {
    std::cout << prefix << ": "
              << "X=" << (int)packet.router_id_x << ", "
              << "Y=" << (int)packet.router_id_y << ", "
              << "Payload=0x" << std::hex << std::setw(8) << std::setfill('0') << packet.payload
              << std::dec << std::endl;
}

// Helper function to determine expected output direction based on XY routing algorithm
Direction determine_route(const RouterPacket& packet, uint8_t current_x, uint8_t current_y) {
    // Implement XY routing algorithm as in router_core.bsv
    if (packet.router_id_x != current_x) {
        if (packet.router_id_x > current_x) {
            return EAST;
        } else {
            return WEST;
        }
    } else if (packet.router_id_y != current_y) {
        if (packet.router_id_y > current_y) {
            return NORTH;
        } else {
            return SOUTH;
        }
    } else {
        return PE;  // Local delivery
    }
}

class RouterTestbench {
private:
    Vmk_router* m_router;
    VerilatedVcdC* m_trace;
    uint64_t m_tickCount;
    uint8_t m_currentX;
    uint8_t m_currentY;
    
    // Helper method to toggle clock and evaluate
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
    
public:
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
        m_router->RST_N = 0;
        for (int i = 0; i < 10; i++) {
            tick();
        }
        m_router->RST_N = 1;
    }
    
    ~RouterTestbench() {
        m_router->final();
        m_trace->close();
        delete m_router;
        delete m_trace;
    }
    
    // Send a packet to a specific virtual channel
    void sendPacket(int vcNum, const RouterPacket& packet) {
        std::cout << "Sending packet to VC" << vcNum << ": ";
        print_packet("", packet);
        
        // Create the 36-bit data packet (2 bits router_id_x + 2 bits router_id_y + 32 bits payload)
        uint64_t data = ((uint64_t)(packet.router_id_x & 0x3) << 34) | 
                       ((uint64_t)(packet.router_id_y & 0x3) << 32) | 
                       (uint64_t)(packet.payload);
        
        // Reset all enable signals
        m_router->EN_queue_data_vc1 = 0;
        m_router->EN_queue_data_vc2 = 0;
        m_router->EN_queue_data_vc3 = 0;
        m_router->EN_queue_data_vc4 = 0;
        
        // Set packet data based on VC number
        switch (vcNum) {
            case 1:
                m_router->queue_data_vc1_data = data;
                m_router->EN_queue_data_vc1 = 1;
                break;
            case 2:
                m_router->queue_data_vc2_data = data;
                m_router->EN_queue_data_vc2 = 1;
                break;
            case 3:
                m_router->queue_data_vc3_data = data;
                m_router->EN_queue_data_vc3 = 1;
                break;
            case 4:
                m_router->queue_data_vc4_data = data;
                m_router->EN_queue_data_vc4 = 1;
                break;
        }
        
        // Tick once to process the input
        tick();
        
        // Reset enable signals
        m_router->EN_queue_data_vc1 = 0;
        m_router->EN_queue_data_vc2 = 0;
        m_router->EN_queue_data_vc3 = 0;
        m_router->EN_queue_data_vc4 = 0;
        
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
    
    // Check outputs from all directions
    void checkOutputs() {
        std::cout << "Checking router outputs at tick " << m_tickCount << std::endl;
        
        // Extract router_id_x (bits 35:34), router_id_y (bits 33:32), and payload (bits 31:0) from output signals
        if (m_router->RDY_router_out_north) {
            uint8_t router_id_x = (m_router->router_out_north >> 34) & 0x3;
            uint8_t router_id_y = (m_router->router_out_north >> 32) & 0x3;
            uint32_t payload = m_router->router_out_north & 0xFFFFFFFF;
            RouterPacket packet(router_id_x, router_id_y, payload);
            print_packet("North output", packet);
        }
        
        if (m_router->RDY_router_out_south) {
            uint8_t router_id_x = (m_router->router_out_south >> 34) & 0x3;
            uint8_t router_id_y = (m_router->router_out_south >> 32) & 0x3;
            uint32_t payload = m_router->router_out_south & 0xFFFFFFFF;
            RouterPacket packet(router_id_x, router_id_y, payload);
            print_packet("South output", packet);
        }
        
        if (m_router->RDY_router_out_east) {
            uint8_t router_id_x = (m_router->router_out_east >> 34) & 0x3;
            uint8_t router_id_y = (m_router->router_out_east >> 32) & 0x3;
            uint32_t payload = m_router->router_out_east & 0xFFFFFFFF;
            RouterPacket packet(router_id_x, router_id_y, payload);
            print_packet("East output", packet);
        }
        
        if (m_router->RDY_router_out_west) {
            uint8_t router_id_x = (m_router->router_out_west >> 34) & 0x3;
            uint8_t router_id_y = (m_router->router_out_west >> 32) & 0x3;
            uint32_t payload = m_router->router_out_west & 0xFFFFFFFF;
            RouterPacket packet(router_id_x, router_id_y, payload);
            print_packet("West output", packet);
        }
    }
    
    // Run simulation for a specified number of cycles
    void run(int cycles) {
        for (int i = 0; i < cycles; i++) {
            tick();
            if (i % 10 == 0) {
                checkOutputs();
            }
        }
    }
};

int main(int argc, char** argv) {
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);
    
    std::cout << "=== NoC Router Verilator Testbench ==="  << std::endl;
    std::cout << "Current router position: (0,0)" << std::endl;
    
    // Create testbench with router at position (0,0)
    RouterTestbench tb(0, 0);
    
    // Test packets for different destinations
    std::vector<RouterPacket> testPackets = {
        RouterPacket(0, 1, 0x12345678),  // North
        RouterPacket(1, 0, 0x87654321),  // East
        RouterPacket(0, 0, 0xABCDEF01),  // Local
        RouterPacket(1, 1, 0x55AA55AA)   // Northeast
    };
    
    // Send packets to different virtual channels
    for (size_t i = 0; i < testPackets.size(); i++) {
        // Send to different VCs (1-4)
        tb.sendPacket((i % 4) + 1, testPackets[i]);
        
        // Run for a few cycles to let the packet propagate
        tb.run(20);
    }
    
    // Run for additional cycles to ensure all packets are processed
    tb.run(50);
    
    std::cout << "Simulation completed successfully!" << std::endl;
    return 0;
}
