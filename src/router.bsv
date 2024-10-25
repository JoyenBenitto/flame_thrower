package router;

import FIFO          ::   *  ;
import FIFOF         ::   *  ;
import router_core   ::   *  ;
import buffer        ::   *  ;
import Arbiter       ::   *  ;
import Vector        ::   *  ;


interface Ifc_router;
    //checks if the queue is available and queue's data
    method Action queue_data_vc1(Router_core_packet data); //data from channel one
    method Action queue_data_vc2(Router_core_packet data); //data from channel two
    method Action queue_data_vc3(Router_core_packet data); //data from channel three
    method Action queue_data_vc4(Router_core_packet data); //data from channel four
    //The below will provide interface wires that can be used to connect
    method ActionValue #(Router_core_packet) router_out_North (); //the arbiter will choose the Input channel to route
    // method ActionValue #(Router_core_packet) router_out_South (Bit#(2) crossbar_selector);
    // method ActionValue #(Router_core_packet) router_out_EAST (Bit#(2) crossbar_selector);
    // method ActionValue #(Router_core_packet) router_out_WEST (Bit#(2) crossbar_selector);
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
    Ifc_buffer vc_1 <- mk_buffer(); //virtual channel 1
    Ifc_buffer vc_2 <- mk_buffer(); //virtual channel 2
    Ifc_buffer vc_3 <- mk_buffer(); //virtual channel 3
    Ifc_buffer vc_4 <- mk_buffer(); //virtual channel 4

    Ifc_router_core rc_vc_1 <- mk_router_core(0,0); //router controller for vc-1
    Ifc_router_core rc_vc_2 <- mk_router_core(0,0); //router controller for vc-2
    Ifc_router_core rc_vc_3 <- mk_router_core(0,0); //router controller for vc-3
    Ifc_router_core rc_vc_4 <- mk_router_core(0,0); //router controller for vc-4

    rule north_arbiteration;
        north_arbiter.clients[0].request();
        north_arbiter.clients[1].request();
        north_arbiter.clients[2].request();
        north_arbiter.clients[3].request();
    endrule

    rule grant_log_display;
        $display($time, " north_vc1 grant status: %d", north_arbiter.clients[0].grant());
        $display($time, " north_vc2 grant status: %d", north_arbiter.clients[1].grant());
        $display($time, " north_vc3 grant status: %d", north_arbiter.clients[2].grant());
        $display($time, " north_vc4 grant status: %d", north_arbiter.clients[3].grant());
        $display("\n");
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

    method ActionValue #(Router_core_packet) router_out_North ();
        actionvalue
            if (north_arbiter.clients[0].grant())begin
                $display("dequeing and poping vc_1 north");
                return vc_1.packet_pop(NORTH);
            end
            else begin
                return vc_2.packet_pop(NORTH);
            end

        endactionvalue
    endmethod
endmodule: mk_router

endpackage: router
