package tb_router;

import Connectable:: * ;
import StmtFSM:: *;
import router:: *;
import router_core:: *;

module mk_tb_router(Empty);

  Ifc_router router_0_0 <- mk_router();
  Ifc_router router_0_1 <- mk_router();
  Ifc_router router_1_0 <- mk_router();
  Ifc_router router_1_1 <- mk_router();

  mkConnection(router_0_0.router_out_north, router_0_1.queue_data_vc1);
  mkConnection(router_0_0.queue_data_vc1, router_0_1.router_out_south);
  mkConnection(router_0_0.router_out_east, router_1_0.queue_data_vc2);
  mkConnection(router_0_0.queue_data_vc4, router_0_1.router_out_west);
  

  // Packet to send
  Reg#(Router_core_packet) packet_reg <- mkReg(
    Router_core_packet {
      router_id_x: 2'b00,
      router_id_y: 2'b01,
      payload: 32'd4
    }
  );

  // Flag to control enqueueing
  Reg#(Bool) enqueued <- mkReg(False);

  // Rule to enqueue the packet
  rule enqueue_packet if (!enqueued);
    router_0_0.queue_data_vc3(packet_reg);
    $display("Testbench: Enqueued packet: router_id_x=%d, router_id_y=%d, payload=%d",
             packet_reg.router_id_x, packet_reg.router_id_y, packet_reg.payload);
    enqueued <= True;
  endrule

  // Registers to hold received packets from each port
  Reg#(Router_core_packet) received_north_reg_0_0 <- mkRegU;
  Reg#(Router_core_packet) received_south_reg_0_0 <- mkRegU;
  Reg#(Router_core_packet) received_east_reg_0_0 <- mkRegU;
  Reg#(Router_core_packet) received_west_reg_0_0 <- mkRegU;
  Reg#(Router_core_packet) received_north_reg_0_1 <- mkRegU;
  Reg#(Router_core_packet) received_south_reg_0_1 <- mkRegU;
  Reg#(Router_core_packet) received_east_reg_0_1 <- mkRegU;
  Reg#(Router_core_packet) received_west_reg_0_1 <- mkRegU;

  // Rule to read the North output
  rule read_north;
    received_north_reg_0_0 <= router_0_0.router_out_north();
    received_north_reg_0_1 <= router_0_1.router_out_north();
    $display("Testbench: Received packet from router_out_north_0_0: router_id_x=%d, router_id_y=%d, payload=%d",
             received_north_reg_0_0.router_id_x, received_north_reg_0_0.router_id_y, received_north_reg_0_0.payload);
    $display("Testbench: Received packet from router_out_north_0_1: router_id_x=%d, router_id_y=%d, payload=%d",
             received_north_reg_0_1.router_id_x, received_north_reg_0_1.router_id_y, received_north_reg_0_1.payload);
  endrule

  // Rule to read the South output
  rule read_south;
    received_south_reg_0_0 <= router_0_0.router_out_south();
    received_south_reg_0_1 <= router_0_0.router_out_south();
    $display("Testbench: Received packet from router_out_south_0_0: router_id_x=%d, router_id_y=%d, payload=%d",
             received_south_reg_0_0.router_id_x, received_south_reg_0_0.router_id_y, received_south_reg_0_0.payload);
    $display("Testbench: Received packet from router_out_south_0_1: router_id_x=%d, router_id_y=%d, payload=%d",
             received_south_reg_0_1.router_id_x, received_south_reg_0_1.router_id_y, received_south_reg_0_1.payload);
  endrule

  // Rule to read the East output
  rule read_east;
    received_east_reg_0_0 <= router_0_0.router_out_east();
    received_east_reg_0_1 <= router_0_1.router_out_east();
    $display("Testbench: Received packet from router_out_east: router_id_x=%d, router_id_y=%d, payload=%d",
             received_east_reg_0_0.router_id_x, received_east_reg_0_0.router_id_y, received_east_reg_0_0.payload);
    $display("Testbench: Received packet from router_out_east: router_id_x=%d, router_id_y=%d, payload=%d",
             received_east_reg_0_1.router_id_x, received_east_reg_0_1.router_id_y, received_east_reg_0_1.payload);
  endrule

  // Rule to read the West output
  rule read_west;
    received_west_reg_0_0 <= router_0_0.router_out_west();
    received_west_reg_0_1 <= router_0_1.router_out_west();
    $display("Testbench: Received packet from router_out_west: router_id_x=%d, router_id_y=%d, payload=%d",
             received_west_reg_0_0.router_id_x, received_west_reg_0_0.router_id_y, received_west_reg_0_0.payload);
    $display("Testbench: Received packet from router_out_west: router_id_x=%d, router_id_y=%d, payload=%d",
             received_west_reg_0_1.router_id_x, received_west_reg_0_1.router_id_y, received_west_reg_0_1.payload);
  endrule

endmodule

endpackage: tb_router
