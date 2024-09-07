
package buffer;

    interface Ifc_buffer;
        method Action push (int x);
        method Action pop;
        method int top;
    endinterface: Ifc_buffer

    (*synthesize*)
    module mkBuffer (Empty);
        rule print_hello;
            $display("prints the content of the fifo");
            $finish;
        endrule
    endmodule: mkBuffer


endpackage: buffer