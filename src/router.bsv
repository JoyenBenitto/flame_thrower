package router;

import FIFO          ::   *  ;
import FIFOF         ::   *  ;
import router_core   ::   *  ;
import buffer        ::   *  ;
import Arbiter       ::   *  ;
import Vector        ::   *  ;


interface Ifc_router;
    method Action queue_data_vc1(Router_core_packet data); //data from channel one
    method Action queue_data_vc2(Router_core_packet data); //data from channel two
    method Action queue_data_vc3(Router_core_packet data); //data from channel three
    method Action queue_data_vc4(Router_core_packet data); //data from channel four
    method Router_core_packet router_out_north ();
    method Router_core_packet router_out_south ();
    method Router_core_packet router_out_east ();
    method Router_core_packet router_out_west ();
endinterface: Ifc_router

(*synthesize*)
module mk_router(Ifc_router);

    /*Virtual channels, the method action queue data will have one phy channel
    connected to the four of the below virtual channel.
    1) Router_Core module will device the direction to route.
    2) Based on the direction buffer direction is encoded and the payload is buffered.
    3) Arbiteration logic after the buffer to pick which has to routed.
    4) The crossbar controlled by the arbiter will output the payload in the respective interface
    */

    Arbiter_IFC#(4) north_arbiter <- mkArbiter(False);
    Arbiter_IFC#(4) south_arbiter <- mkArbiter(False);
    Arbiter_IFC#(4) east_arbiter <- mkArbiter(False);
    Arbiter_IFC#(4) west_arbiter <- mkArbiter(False);

    //The buffer is arranged in a SAFQ (Statically allocated fixed queue) manner
    Ifc_buffer vc_1 <- mk_buffer(); //virtual channel 1 NE
    Ifc_buffer vc_2 <- mk_buffer(); //virtual channel 2 WE
    Ifc_buffer vc_3 <- mk_buffer(); //virtual channel 3 SE
    Ifc_buffer vc_4 <- mk_buffer(); //virtual channel 4 EE

    Ifc_router_core rc_vc_1 <- mk_router_core(0,0); //router controller for vc-1
    Ifc_router_core rc_vc_2 <- mk_router_core(0,0); //router controller for vc-2
    Ifc_router_core rc_vc_3 <- mk_router_core(0,0); //router controller for vc-3
    Ifc_router_core rc_vc_4 <- mk_router_core(0,0); //router controller for vc-4

    Reg#(Router_core_packet) north_wire <- mkRegU;
    Reg#(Router_core_packet) south_wire <- mkRegU;
    Reg#(Router_core_packet) east_wire <- mkRegU;
    Reg#(Router_core_packet) west_wire <- mkRegU;

    rule north_arbiteration;
        north_arbiter.clients[0].request();
        north_arbiter.clients[1].request();
        north_arbiter.clients[2].request();
        north_arbiter.clients[3].request();
    endrule


    rule south_arbiteration;
        south_arbiter.clients[0].request();
        south_arbiter.clients[1].request();
        south_arbiter.clients[2].request();
        south_arbiter.clients[3].request();
    endrule

    rule east_arbiteration;
        east_arbiter.clients[0].request();
        east_arbiter.clients[1].request();
        east_arbiter.clients[2].request();
        east_arbiter.clients[3].request();
    endrule

    rule west_arbiteration;
        west_arbiter.clients[0].request();
        west_arbiter.clients[1].request();
        west_arbiter.clients[2].request();
        west_arbiter.clients[3].request();
    endrule

    //North out
    rule north_grant_vc1 (north_arbiter.clients[0].grant()); begin
        $display($time, " north_vc1 grant status: %d", north_arbiter.clients[0].grant());
        let north_data <- vc_1.packet_pop(NORTH);
        north_wire <= north_data;
        end
    endrule


    rule north_grant_vc2 (north_arbiter.clients[1].grant()); begin
        $display($time, " north_vc1 grant status: %d", north_arbiter.clients[1].grant());
        let north_data <- vc_2.packet_pop(NORTH);
        north_wire <= north_data;
        end
    endrule


    rule north_grant_vc3 (north_arbiter.clients[2].grant()); begin
        $display($time, " north_vc1 grant status: %d", north_arbiter.clients[2].grant());
        let north_data <- vc_3.packet_pop(NORTH);
        north_wire <= north_data;
        end
    endrule

    rule north_grant_vc4 (north_arbiter.clients[3].grant()); begin
        $display($time, " north_vc1 grant status: %d", north_arbiter.clients[3].grant());
        let north_data <- vc_4.packet_pop(NORTH);
        north_wire <= north_data;
        end
    endrule


    //south out
    rule south_grant_vc1 (south_arbiter.clients[0].grant()); begin
        $display($time, " south_vc1 grant status: %d", south_arbiter.clients[0].grant());
        let south_data <- vc_1.packet_pop(SOUTH);
        south_wire <= south_data;
        end
    endrule


    rule south_grant_vc2 (south_arbiter.clients[1].grant()); begin
        $display($time, " south_vc1 grant status: %d", south_arbiter.clients[1].grant());
        let south_data <- vc_2.packet_pop(SOUTH);
        south_wire <= south_data;
        end
    endrule


    rule south_grant_vc3 (south_arbiter.clients[2].grant()); begin
        $display($time, " south_vc1 grant status: %d", south_arbiter.clients[2].grant());
        let south_data <- vc_3.packet_pop(SOUTH);
        south_wire <= south_data;
        end
    endrule

    rule south_grant_vc4 (south_arbiter.clients[3].grant()); begin
        $display($time, " south_vc1 grant status: %d", south_arbiter.clients[3].grant());
        let south_data <- vc_4.packet_pop(SOUTH);
        south_wire <= south_data;
        end
    endrule

    //east out
    rule east_grant_vc1 (east_arbiter.clients[0].grant()); begin
        $display($time, " east_vc1 grant status: %d", east_arbiter.clients[0].grant());
        let east_data <- vc_1.packet_pop(EAST);
        east_wire <= east_data;
        end
    endrule

    rule east_grant_vc2 (east_arbiter.clients[1].grant()); begin
        $display($time, " east_vc1 grant status: %d", east_arbiter.clients[1].grant());
        let east_data <- vc_2.packet_pop(EAST);
        east_wire <= east_data;
        end
    endrule


    rule east_grant_vc3 (east_arbiter.clients[2].grant()); begin
        $display($time, " east_vc1 grant status: %d", east_arbiter.clients[2].grant());
        let east_data <- vc_3.packet_pop(EAST);
        east_wire <= east_data;
        end
    endrule

    rule east_grant_vc4 (east_arbiter.clients[3].grant()); begin
        $display($time, " east_vc1 grant status: %d", east_arbiter.clients[3].grant());
        let east_data <- vc_4.packet_pop(EAST);
        east_wire <= east_data;
        end
    endrule


    //west out
    rule west_grant_vc1 (west_arbiter.clients[0].grant()); begin
        $display($time, " west_vc1 grant status: %d", west_arbiter.clients[0].grant());
        let west_data <- vc_1.packet_pop(WEST);
        west_wire <= west_data;
        end
    endrule

    rule west_grant_vc2 (west_arbiter.clients[1].grant()); begin
        $display($time, " west_vc1 grant status: %d", west_arbiter.clients[1].grant());
        let west_data <- vc_2.packet_pop(WEST);
        west_wire <= west_data;
        end
    endrule

    rule west_grant_vc3 (west_arbiter.clients[2].grant()); begin
        $display($time, " west_vc1 grant status: %d", west_arbiter.clients[2].grant());
        let west_data <- vc_3.packet_pop(WEST);
        west_wire <= west_data;
        end
    endrule

    rule west_grant_vc4 (west_arbiter.clients[3].grant()); begin
        $display($time, " west_vc1 grant status: %d", west_arbiter.clients[3].grant());
        let west_data <- vc_4.packet_pop(WEST);
        west_wire <= west_data;
        end
    endrule

    method Action queue_data_vc1(Router_core_packet incoming_packet);
        action
            Direction dir <- rc_vc_1.router_core(incoming_packet);
            vc_1.queue_data(dir, incoming_packet);
        endaction
    endmethod

    method Action queue_data_vc2(Router_core_packet incoming_packet);
        action
            Direction dir <- rc_vc_2.router_core(incoming_packet);
            vc_2.queue_data(dir, incoming_packet);
        endaction
    endmethod

    method Action queue_data_vc3(Router_core_packet incoming_packet);
        action
            Direction dir <- rc_vc_3.router_core(incoming_packet);
            vc_3.queue_data(dir, incoming_packet);
        endaction
    endmethod

    method Action queue_data_vc4(Router_core_packet incoming_packet);
        action
            Direction dir <- rc_vc_4.router_core(incoming_packet);
            vc_4.queue_data(dir, incoming_packet);
        endaction
    endmethod

    method Router_core_packet router_out_north();
        return north_wire;
    endmethod

    method Router_core_packet router_out_south();
        return south_wire;
    endmethod

    method Router_core_packet router_out_east();
        return east_wire;
    endmethod

    method Router_core_packet router_out_west();
        return west_wire;
    endmethod

endmodule: mk_router

endpackage: router
