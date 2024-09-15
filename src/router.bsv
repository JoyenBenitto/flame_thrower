package router;

import buffer::*; // Import everything from the buffer package

(*synthesize*)
module mk_router();
    // Declare the buffer interface
    Ifc_buffer buffer <- mkBuffer();

    // Access the buffer instance here
    Bit#(32) data= 32'd32;

    Reg#(Bool) status<- mkReg(True);

    rule update_status;
        status <= buffer.check_queue_availability();
    endrule

    rule send_data (True);
        if (status) begin
            $display($time," :sending data %d", status);
            buffer.push_data(data);
        end
        else begin
            $display($time," :router queue is full");
            $finish;
        end
    endrule

endmodule: mk_router

endpackage: router
