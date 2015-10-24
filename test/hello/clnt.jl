using Thrift
import Thrift.process, Thrift.meta

# include the generated hello module
include("gen-jl/hello/hello.jl");
import hello.SayHelloClient, hello.hello_to

# create a client instance with our choice of protocol and transport
clnt_transport = TSocket(19999)
proto = TBinaryProtocol(clnt_transport)
clnt = SayHelloClient(proto)

# open a connection
open(clnt_transport)
# invoke service and print the result
println(hello_to(clnt, "Julia"))
# close connection
close(clnt_transport)

