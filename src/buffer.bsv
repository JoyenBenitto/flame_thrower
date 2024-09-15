
package buffer;

import FIFO::*;
import FIFOF::*;

interface Ifc_buffer;
    method Action push_data (Bit#(32) data); 
    /*32 bit input interface that will send 32 bit data inside the module*/
    method Bool check_queue_availability(); 
    /*Will provide one bit signal to check if the buffer can accept flits*/
    method ActionValue #(Bit#(32)) pop();
endinterface: Ifc_buffer

(*synthesize*)
module mkBuffer(Ifc_buffer);

    FIFOF#(Bit#(32)) queue <- mkSizedFIFOF(4); 

    rule display_fifo_contents;
        if (queue.notFull) begin
            Bit#(32) data = queue.first();
            $display($time," :FIFO contains: %d", data);
        end
    endrule

    Wire#(Bool) queue_status <- mkWire();

    rule updater;
        queue_status <= queue.notFull();
    endrule

    rule disp;
        $display($time," :some val--> %d", queue_status);
        if (queue_status == False) begin
            $finish;
        end
    endrule

    method Bool check_queue_availability();
        return queue_status; // Return True if the queue is not full, otherwise return False
    endmethod

    method ActionValue #(Bit#(32)) pop();
        return queue.first();
    endmethod

    // Create a FIFO of size 4
    method Action push_data (Bit#(32) flit);
        action
            queue.enq(flit);
        endaction
    endmethod

endmodule: mkBuffer

endpackage: buffer