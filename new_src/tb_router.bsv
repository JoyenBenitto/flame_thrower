package tb_router;

import router :: * ;

(*synthesize*)
module mk_tb_router(Empty);

    Ifc_router#(Bit#(32)) r_00 <- mk_router();

    rule writing_val;
        $display("writing 32 bit val 1 to the register");
        r_00.packet_in_port_n(32'd8);
        $finish;
    endrule

endmodule: mk_tb_router
endpackage: tb_router