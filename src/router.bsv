package router;

import buffer::*; // Import everything from the buffer package

(*synthesize*)
module mk_router();
    // Declare the buffer interface
    Ifc_buffer buffer <- mkBuffer();

    // Access the buffer instance here
    Bit#(32) data= 32'd32;
    rule send_data;
        Bool status <- buffer.check_queue_availability();
        $display("sending data %d", status);
        if (status) begin
            $display("sending data %d", status);
            buffer.push_data(data);
        end
        else begin
            $display("router queue is full");
            $finish;
        end
    endrule

endmodule: mk_router

endpackage: router
