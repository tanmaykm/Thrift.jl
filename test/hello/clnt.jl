using Thrift
import Thrift.process, Thrift.meta

# include the generated hello module
include("gen-jl/hello/hello.jl");

# create a client instance with our choice of protocol and transport
clnt_transport = TSocket(19999)
proto = TBinaryProtocol(clnt_transport)
clnt = hello.SayHelloClient(proto)

# open a connection
open(clnt_transport)
# invoke service and print the result
println(hello.hello_to(clnt, "Julia"))
# close connection
close(clnt_transport)

