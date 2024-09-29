package crossbar;

import router_core :: * ;

interface Ifc_corssbar;
    method ActionValue #(Router_core_packet) data_out(Direction dir, Vector#(4, Router_core_packet) pkt);
endinterface

module mkCrossbar(Ifc_corssbar);

    /*The idea is that the router will accept one of the input from the four VC
    and output it based on the arbiter connected*/

    method ActionValue #(Router_core_packet) data_out(Bit#(2) queue_id, Vector#(4, Router_core_packet) pkt);
        actionvalue
            case (queue_id) matches
                2'd0: return pkt[0];
                2'd1: return pkt[1];
                2'd2: return pkt[2];
                2'd3: return pkt[3];
            endcase
        endaction
    endmethod

endmodule: mkCrossbar

endpackage crossbar