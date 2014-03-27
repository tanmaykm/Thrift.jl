using Thrift
import Thrift.process, Thrift.meta

testdir = joinpath(Pkg.dir("Thrift"), "test")

run(`thrift -gen jl proto_tests.thrift`)
println("Compiled IDL...")
cp(joinpath(testdir, "proto_tests_impl.jl"), joinpath(testdir, "gen-jl", "proto_tests", "proto_tests_impl.jl"))
println("Added service implementation...")


# include the generated module, which in-turn includes our implementation code in `proto_tests_impl.jl`
# prepend with @everywhere when running a TProcessPoolServer on multiple Julia processors
#@everywhere include("gen-jl/proto_tests/proto_tests.jl")
include("gen-jl/proto_tests/proto_tests.jl");
import proto_tests: ProtoTestsProcessor, ProtoTestsClient, test_hello

transport_factory(x) = x
protocol_factory(x) = TBinaryProtocol(x)
#protocol_factory(x) = TCompactProtocol(x)

function make_server()
    # create a server instance with our choice of protocol and transport
    srvr_processor = ProtoTestsProcessor()
    srvr_transport = TServerSocket(9999)

    #srvr = TProcessPoolServer(srvr_transport, srvr_processor, transport_factory, protocol_factory, transport_factory, protocol_factory)
    #srvr = TTaskServer(srvr_transport, srvr_processor, transport_factory, protocol_factory, transport_factory, protocol_factory)
    srvr = TSimpleServer(srvr_transport, srvr_processor, transport_factory, protocol_factory, transport_factory, protocol_factory)

    println("Transport: $(typeof(srvr_transport))")
    println("Protocol : $(typeof(protocol_factory(srvr_transport)))")
    println("Processor: $(typeof(srvr_processor))")
    println("Server   : $(typeof(srvr))")
    srvr
end

srvr = make_server()
# start serving client requests
println("Starting to serve requests...")
@async serve(srvr)

# create a client instance with our choice of protocol and transport
clnt_transport = TSocket(9999)
#proto = TCompactProtocol(clnt_transport)
proto = TBinaryProtocol(clnt_transport)
clnt = ProtoTestsClient(proto)

function run_client(n=10)
    println("Transport: $(typeof(clnt_transport))")
    println("Protocol : $(typeof(proto))")
    println("Starting requests...")

    # open a connection
    open(clnt_transport)
    # invoke service and print the result
    for i in 1:n
        println(test_hello(clnt, "Julia"))
    end
    # close connection
    close(clnt_transport)
end


println("Waiting for server to start...")
sleep(5)
run_client()
