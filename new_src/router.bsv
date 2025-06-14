package router;
// Router top module

import FIFOF        :: * ;
import Vector       :: * ;
import SpecialFIFOs :: * ;

`define FIFO_DEPTH 5
`define NUM_PORTS 4

interface Ifc_router #(type data_t);
    method data_t packet_out_port_n();  //north output port
    method data_t packet_out_port_s();  //south output port
    method data_t packet_out_port_e();  //east output port
    method data_t packet_out_port_w();  //west output port
    method Action packet_in_port_n(data_t packet_inp); //north input port
    method Action packet_in_port_s(data_t packet_inp); //south input port
    method Action packet_in_port_e(data_t packet_inp); //east input port
    method Action packet_in_port_w(data_t packet_inp); //west input port
endinterface: Ifc_router

(*synthesize*)
module mk_router(Ifc_router#(Bit#(32)));

    //Creating a register
    Vector#(`NUM_PORTS, FIFOF#(Bit#(32))) port_in <- replicateM(mkSizedBypassFIFOF(`FIFO_DEPTH));
    Vector#(`NUM_PORTS, FIFOF#(Bit#(32))) port_out <- replicateM(mkSizedBypassFIFOF(`FIFO_DEPTH));

    method Bit#(32) packet_out_port_n();
        return port_in[0].first;
    endmethod
    method Bit#(32) packet_out_port_s();
        return port_in[1].first;
    endmethod
    method Bit#(32) packet_out_port_e();
        return port_in[2].first;
    endmethod
    method Bit#(32) packet_out_port_w();
        return port_in[3].first;
    endmethod
    method Action packet_in_port_n(Bit#(32) packet_inp);
        port_out[0].enq(packet_inp);
    endmethod
    method Action packet_in_port_s(Bit#(32) packet_inp);
        port_out[1].enq(packet_inp);
    endmethod
    method Action packet_in_port_e(Bit#(32) packet_inp);
        port_out[2].enq(packet_inp);
    endmethod
    method Action packet_in_port_w(Bit#(32) packet_inp);
        port_out[3].enq(packet_inp);
    endmethod

endmodule: mk_router

endpackage: router
