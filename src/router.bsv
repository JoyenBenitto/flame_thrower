package router;

import FIFO          ::   *  ;
import FIFOF         ::   *  ;
import router_core   ::   *  ;
import buffer        ::   *  ;

interface Ifc_router;
    //checks if the queue is available and queue's data
    method Action queue_data_vc1(Router_core_packet data); //data from channel one
    method Action queue_data_vc2(Router_core_packet data); //data from channel two
    method Action queue_data_vc3(Router_core_packet data); //data from channel three
    method Action queue_data_vc4(Router_core_packet data); //data from channel four
    //The below will provide interface wires that can be used to conect
    //method ActionValue #(Router_core_packet) router_out_North (Bit#(2) crossbar_selector); //the arbiter will choose the Input channel to route
    //method ActionValue #(Router_core_packet) router_out_South (Bit#(2) crossbar_selector);
    //method ActionValue #(Router_core_packet) router_out_EAST (Bit#(2) crossbar_selector);
    //method ActionValue #(Router_core_packet) router_out_WEST (Bit#(2) crossbar_selector);
endinterface: Ifc_router

(*synthesize*)
module mk_router(Ifc_router);

    /*Virtual channels, the method action queue data will have one phy channel
    connected to the four of the below virtual channel.
    1) Router_Core module will device the direction to route.
    2) Based on the direction buffer direction is encoded and the payload is buffered.
    3) Arbiteration logic after the buffer to pick which has to routed.
    4) The crossbar controlled by the arbitter will output the payload in the respective interface
    */

    //The buffer is arranged in a SAMQ (Statically allocated multiqueue) manner
    Ifc_buffer vc_1 <- mk_buffer(); //virtual channel 1
    Ifc_buffer vc_2 <- mk_buffer(); //virtual channel 2
    Ifc_buffer vc_3 <- mk_buffer(); //virtual channel 3
    Ifc_buffer vc_4 <- mk_buffer(); //virtual channel 4

    Ifc_router_core rc_vc_1 <- mk_router_core(0,0); //router controler for vc-1
    Ifc_router_core rc_vc_2 <- mk_router_core(0,0); //router controler for vc-2
    Ifc_router_core rc_vc_3 <- mk_router_core(0,0); //router controler for vc-3
    Ifc_router_core rc_vc_4 <- mk_router_core(0,0); //router controler for vc-4

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

endmodule: mk_router

endpackage: router
