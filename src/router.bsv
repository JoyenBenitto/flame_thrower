package router;

import FIFO      ::   *  ;
import FIFOF     ::   *  ;
import buffer    ::   *  ;

interface Ifc_router;
    //checks if the queue is available and queue's data
    method Action queue_data_vc1(Packet data); //data from channel one
    method Action queue_data_vc2(Packet data); //data from channel two
    method Action queue_data_vc3(Packet data); //data from channel three
    method Action queue_data_vc4(Packet data); //data from channel four
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

    method Action queue_data_vc1(Packet incoming_packet);
        action
            vc_1.queue_data(incoming_packet.dest, incoming_packet.payload);
        endaction
    endmethod
    method Action queue_data_vc2(Packet incoming_packet);
        action
            vc_2.queue_data(incoming_packet.dest, incoming_packet.payload);
        endaction
    endmethod
    method Action queue_data_vc3(Packet incoming_packet);
        action
            vc_3.queue_data(incoming_packet.dest, incoming_packet.payload);
        endaction
    endmethod
    method Action queue_data_vc4(Packet incoming_packet);
        action
            vc_4.queue_data(incoming_packet.dest, incoming_packet.payload);
        endaction
    endmethod

endmodule: mk_router

endpackage: router
