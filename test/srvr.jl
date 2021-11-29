using Thrift
using Test

import Thrift: process, meta


global srvr

# include the generated module, which in-turn includes our implementation code in `proto_tests_impl.jl`
# prepend with @everywhere when running a TProcessPoolServer on multiple Julia processors
@isdefined(srvcctrl) || include("gen-jl/srvcctrl/srvcctrl.jl");
@isdefined(proto_tests) || include("gen-jl/proto_tests/proto_tests.jl");

import .proto_tests: ProtoTestsProcessor, ProtoTestsClient, InvalidOperation, AllTypes, AllTypesDefault, TestEnum
import .proto_tests: test_hello, test_exception, test_oneway, ping, test_enum, test_types, test_types_default
import .srvcctrl: start_service, stop_service

# transport_factory(x) = x
# protocol_factory(x) = TBinaryProtocol(x)
# protocol_factory(x) = TCompactProtocol(x)
transport_factory(x) = THeaderTransport(x)
protocol_factory(x) = THeaderProtocol(TBinaryProtocol(x))

function make_server()
    # create a server instance with our choice of protocol and transport
    srvr_processor = ProtoTestsProcessor()
    srvr_transport = TServerSocket(19999)

    #srvr = TProcessPoolServer(srvr_transport, srvr_processor, transport_factory, protocol_factory, transport_factory, protocol_factory)
    #srvr = TTaskServer(srvr_transport, srvr_processor, transport_factory, protocol_factory, transport_factory, protocol_factory)
    srvr = TSimpleServer(srvr_transport, srvr_processor, transport_factory, protocol_factory, transport_factory, protocol_factory)

    @info("server transport: $(typeof(srvr_transport))")
    @info("server protocol : $(typeof(protocol_factory(srvr_transport)))")
    @info("server processor: $(typeof(srvr_processor))")
    @info("server type: $(typeof(srvr))")
    srvr
end

srvr = make_server()
# start serving client requests
@debug("server starting to serve requests...")

if haskey(ENV, "TEST_SRVR_ASYNC")
    @async try
        start_service(srvr)
    catch ex
        isa(ex, Base.IOError) || @error("Server stopped with $ex")
    finally
        @info("server stopped serving requests.")
    end
else
    start_service(srvr)
end
