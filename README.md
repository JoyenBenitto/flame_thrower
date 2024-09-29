# Flame Thrower

Flame thrower is a On-Chip Network router written in bluespec (Can be compiled down to verilog).

# Building the router

```
$ git clone https://github.com/JoyenBenitto/flame_thrower.git
$ cd flame_thrower
$ make generate_verilog
```

# Feature list for `0.1.0`:
- 4 Statically allocated Multi Queue buffers (`SAMQ`), which provide VCs(virtual channels) for incoming flits from north, south, east and west direction, also provides a
VC for associated processing element.
- 4 x 4x1 crossbar interface, provide interface to connect and communicate with a mesh topology of routers.
- Round Robin Arbiter (No priority arbiteration added yet).
- XY routing scheme (Route along the X direction and then Y as in this routing scheme the location of every router is known).

![router_diag](./docs/router_arch.svg)

>[!NOTE]
The above architercture does bring in a lot of drawbacks, for example the duplication of hardware for every direction such as the need for 4 4x1 crossbars and a seperate 
arbiter for each and ofcourse some of the virtual channels may go unused if the traffic is not uniform. The later version of the router are expected to overcome these drawbacks. 
