
package buffer;

import FIFO   ::  *;
import FIFOF  ::  *;

//some macros
`define FIFO_WIDTH 32
`define FIFO_DEPTH 5


typedef enum {
    NORTH,
    SOUTH,
    EAST,
    WEST,
    PE
    } Direction deriving(Bits, Eq);

    //type of the packets
typedef struct {
    Bit#(`FIFO_WIDTH) payload;
} Payload deriving (Bits, Eq);

typedef struct {
    Direction dest;  // 8-bit destination address
    Payload payload; // 32-bit data payload
} Packet deriving (Bits, Eq);
    
interface Ifc_buffer;
    //checks if the queue is available and queue's data
    method Action queue_data(Direction fifo_id, Payload data);
    method ActionValue #(Payload) packet_pop(Direction fifo_id);
endinterface: Ifc_buffer

(*synthesize*)
module mk_buffer(Ifc_buffer);
    //FIFO bank
    FIFOF#(Payload) north <- mkSizedFIFOF(`FIFO_DEPTH);
    FIFOF#(Payload) south <- mkSizedFIFOF(`FIFO_DEPTH);
    FIFOF#(Payload) east <- mkSizedFIFOF(`FIFO_DEPTH);
    FIFOF#(Payload) west <- mkSizedFIFOF(`FIFO_DEPTH);
    FIFOF#(Payload) pe <- mkSizedFIFOF(`FIFO_DEPTH);

    method Action queue_data(Direction fifo_id, Payload data);
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

    method ActionValue #(Payload) packet_pop(Direction fifo_id);
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