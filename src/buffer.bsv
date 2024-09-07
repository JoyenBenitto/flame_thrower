
package buffer;

import FIFO::*;
import FIFOF::*;

interface Ifc_buffer;
    method Action push_data (Bit#(32) data); 
    /*32 bit input interface that will send 32 bit data inside the module*/
    method ActionValue #(Bool) check_queue_availability(); 
    /*Will provide one bit signal to check if the buffer can accept flits*/
    method ActionValue #(Bit#(32)) pop();
endinterface: Ifc_buffer

(*synthesize*)
module mkBuffer(Ifc_buffer);

    FIFOF#(Bit#(32)) queue <- mkSizedFIFOF(8); 

    rule display_fifo_contents;
        if (queue.notFull) begin
            Bit#(32) data = queue.first();
            $display("FIFO contains: %d", data);
        end
    endrule

    method ActionValue #(Bool) check_queue_availability();
        actionvalue
            return queue.notFull(); // Return True if the queue is not full, otherwise return False
        endactionvalue
    endmethod

    method ActionValue #(Bit#(32)) pop();
        actionvalue
            return queue.first();
        endactionvalue
    endmethod

    // Create a FIFO of size 4
    method Action push_data (Bit#(32) flit);
        action
            queue.enq(flit);
        endaction
    endmethod


endmodule: mkBuffer

endpackage: buffer