using Thrift
using Compat
using Compat.Test

import Thrift.process, Thrift.meta


global srvr

# include the generated module, which in-turn includes our implementation code in `proto_tests_impl.jl`
# prepend with @everywhere when running a TProcessPoolServer on multiple Julia processors
#@everywhere include("gen-jl/proto_tests/proto_tests.jl")
if VERSION < v"0.7.0-alpha"
    isdefined(:srvcctrl) || include("gen-jl/srvcctrl/srvcctrl.jl");
    isdefined(:proto_tests) || include("gen-jl/proto_tests/proto_tests.jl");
else
    @isdefined(srvcctrl) || include("gen-jl/srvcctrl/srvcctrl.jl");
    @isdefined(proto_tests) || include("gen-jl/proto_tests/proto_tests.jl");
end
import .proto_tests: ProtoTestsProcessor, ProtoTestsClient, InvalidOperation, AllTypes, AllTypesDefault, TestEnum
import .proto_tests: test_hello, test_exception, test_oneway, ping, test_enum, test_types, test_types_default
import .srvcctrl: start_service, stop_service

transport_factory(x) = x
protocol_factory(x) = TBinaryProtocol(x)
#protocol_factory(x) = TCompactProtocol(x)

function make_server()
    # create a server instance with our choice of protocol and transport
    srvr_processor = ProtoTestsProcessor()
    srvr_transport = TServerSocket(19999)

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

if haskey(ENV, "TEST_SRVR_ASYNC")
    @async try
        start_service(srvr)
    catch ex
        println("Server stopped with $ex")
    finally
        println("Stopped serving requests.")
    end
else
    start_service(srvr)
end
