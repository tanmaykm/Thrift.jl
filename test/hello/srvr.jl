using Thrift
import Thrift.process, Thrift.meta

# include the generated module, which in-turn includes our implementation code in `hello_impl.jl`
include("gen-jl/hello/hello.jl");

# create a server instance with our choice of protocol and transport
srvr_processor = hello.SayHelloProcessor()
srvr_transport = TServerSocket(19999)
srvr = TSimpleServer(srvr_transport, srvr_processor, x->x, x->TBinaryProtocol(x), x->x, x->TBinaryProtocol(x))

# start serving client requests
println("starting to serve requests...")
serve(srvr)

