package router_core;

`define NUMBER_OF_ROUTERS_x 2
`define NUMBER_OF_ROUTERS_y 2
`define PAYLOAD_WIDTH 32
`define XY_ROUTING True
`define YX_ROUTING False

typedef enum {
    NORTH,
    SOUTH,
    EAST,
    WEST,
    PE } Direction deriving(Bits, Eq);

//function with logic to perform the xy routing
function Direction xy_routing(Router_core_packet packet, Bit#(`NUMBER_OF_ROUTERS_x) curr_router_id_x, 
Bit#(`NUMBER_OF_ROUTERS_y) curr_router_id_y);

    Direction dir= ?;
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
endfunction


function Direction yx_routing(Router_core_packet packet, Bit#(`NUMBER_OF_ROUTERS_x) curr_router_id_x, 
Bit#(`NUMBER_OF_ROUTERS_y) curr_router_id_y);

    Direction dir= ?;
    if (packet.router_id_y != curr_router_id_y) begin
        if (packet.router_id_y > curr_router_id_y) begin
            dir= NORTH;
        end
        else if (packet.router_id_y < curr_router_id_y)begin
            dir= SOUTH;
        end
    end

    else if (packet.router_id_y == curr_router_id_y) begin
        if (packet.router_id_x > curr_router_id_x) begin
            dir= EAST;
        end
        else if (packet.router_id_x < curr_router_id_x)begin
            dir= WEST;
        end
    end
    else if ((packet.router_id_y == curr_router_id_y) &&
        (packet.router_id_y == curr_router_id_y)) begin
        dir = PE;
    end
    return dir;
endfunction

//The network interface sends data in this particular format
typedef struct{
    Bit#(`NUMBER_OF_ROUTERS_x) router_id_x; //the x id
    Bit#(`NUMBER_OF_ROUTERS_y) router_id_y; //the y id
    Bit#(`PAYLOAD_WIDTH) payload; //the data
} Router_core_packet deriving(Bits, Eq);

interface Ifc_router_core;
    //sends the packet into the correct buffer for routing
    method ActionValue #(Direction) router_core (Router_core_packet packet);
endinterface

//for now we will follow xy routing
module mk_router_core #(Bit#(`NUMBER_OF_ROUTERS_x) curr_router_id_x, Bit#(`NUMBER_OF_ROUTERS_y) curr_router_id_y) 
    (Ifc_router_core);

    method ActionValue #(Direction) router_core (Router_core_packet packet);
        actionvalue
            `ifdef XY_ROUTING
                return xy_routing(packet, curr_router_id_x, curr_router_id_y);
            `elsif YX_ROUTING
                return yx_routing(packet, curr_router_id_x, curr_router_id_y);
            else
                return xy_routing(packet, curr_router_id_x, curr_router_id_y);
            `endif
        endactionvalue
    endmethod
endmodule

endpackage: router_core
