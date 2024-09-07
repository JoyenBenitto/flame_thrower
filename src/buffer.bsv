
package buffer;

import FIFO::*;
import FIFOF::*;


(*synthesize*)
module mkBuffer();
    
    // Create a FIFO of size 4
    FIFOF#(Bit#(32)) queue <- mkSizedFIFOF(4); 

    // Rule to print a message if the FIFO is not full
    rule print_not_full if (queue.notFull);
        $display("FIFO is not full. Ready to enqueue data.");
        Bit#(32) data = 32'd02;
        queue.enq(data);
    endrule

    rule print_full if (!queue.notFull);
        $display("FIFO is full");
        $finish;
    endrule

endmodule: mkBuffer


endpackage: buffer