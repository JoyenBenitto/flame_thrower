package router_core;

`define NUMBER_OF_ROUTERS_x 2
`define NUMBER_OF_ROUTERS_y 2
`define PAYLOAD_WIDTH 32

typedef enum {
    NORTH,
    SOUTH,
    EAST,
    WEST,
    PE } Direction deriving(Bits, Eq);

//The payload type
typedef Bit#(`PAYLOAD_WIDTH) Payload;

//The network interface sends data in this particular format
typedef struct{
    Bit#(`NUMBER_OF_ROUTERS_x) router_id_x; //the x id
    Bit#(`NUMBER_OF_ROUTERS_y) router_id_y; //the y id
    Payload payload; //the data
} Router_core_packet deriving(Bits, Eq);

interface Ifc_router_core;
    //sends the packet into the correct buffer for routing
    method ActionValue #(Direction) router_core (Router_core_packet packet);
endinterface

//for now we will follow xy routing
(*synthesize*)
module mk_router_core #(Bit#(`NUMBER_OF_ROUTERS_x) curr_router_id_x, Bit#(`NUMBER_OF_ROUTERS_y) curr_router_id_y) 
    (Ifc_router_core);

    method ActionValue #(Direction) router_core (Router_core_packet packet);
        Direction dir= ?;
        actionvalue
            if (packet.router_id_x != curr_router_id_x) begin
                if (packet.router_id_x > curr_router_id_x) begin
                    dir= EAST;
                end
                else if (packet.router_id_x < curr_router_id_x)begin
                    dir= WEST;
                end
            end
        
            else if (packet.router_id_x == curr_router_id_x) begin
                if (packet.router_id_y > curr_router_id_y) begin
                    dir= NORTH;
                end
                else if (packet.router_id_y < curr_router_id_y)begin
                    dir= SOUTH;
                end
            end
            else if ((packet.router_id_x == curr_router_id_x) &&
                (packet.router_id_x == curr_router_id_x)) begin
                dir = PE;
            end
            return dir;
        endactionvalue
    endmethod
endmodule

endpackage: router_core
