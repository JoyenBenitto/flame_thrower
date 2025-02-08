
package buffer;

import FIFO          ::  *;
import FIFOF         ::  *;
import router_core   ::  *;

//some macros
`define FIFO_DEPTH 5

interface Ifc_buffer;
    //checks if the queue is available and queue's data
    method Action queue_data(Direction fifo_id, Router_core_packet data);
    method ActionValue #(Router_core_packet) packet_pop(Direction fifo_id);
endinterface: Ifc_buffer

module mk_buffer(Ifc_buffer);
    //FIFO bank
    FIFOF#(Router_core_packet) north <- mkSizedFIFOF(`FIFO_DEPTH);
    FIFOF#(Router_core_packet) south <- mkSizedFIFOF(`FIFO_DEPTH);
    FIFOF#(Router_core_packet) east <- mkSizedFIFOF(`FIFO_DEPTH);
    FIFOF#(Router_core_packet) west <- mkSizedFIFOF(`FIFO_DEPTH);
    FIFOF#(Router_core_packet) pe <- mkSizedFIFOF(`FIFO_DEPTH);

    method Action queue_data(Direction fifo_id, Router_core_packet data);
        action
            case (fifo_id) matches
                NORTH: north.enq(data);
                SOUTH: south.enq(data);
                EAST: east.enq(data);
                WEST: west.enq(data);
                PE: pe.enq(data);
            endcase
        endaction
    endmethod: queue_data

    method ActionValue #(Router_core_packet) packet_pop(Direction fifo_id);
        actionvalue
            case (fifo_id) matches
                NORTH: north.deq();
                SOUTH: south.deq();
                EAST: east.deq();
                WEST: west.deq();
                PE: pe.deq();
            endcase

            case (fifo_id) matches
                NORTH: return north.first();
                SOUTH: return south.first();
                EAST: return east.first();
                WEST: return west.first();
                PE: return pe.first();
            endcase
        endactionvalue
    endmethod: packet_pop
endmodule: mk_buffer

endpackage: buffer
