using Thrift
using Base.Test

import Thrift.process, Thrift.meta

testdir = joinpath(Pkg.dir("Thrift"), "test")

run(`thrift -gen jl srvcctrl.thrift`)
run(`thrift -gen jl proto_tests.thrift`)
println("Compiled IDLs...")
cp(joinpath(testdir, "srvcctrl_impl.jl"), joinpath(testdir, "gen-jl", "srvcctrl", "srvcctrl_impl.jl"); remove_destination=true)
cp(joinpath(testdir, "proto_tests_impl.jl"), joinpath(testdir, "gen-jl", "proto_tests", "proto_tests_impl.jl"); remove_destination=true)
println("Added service implementations...")

global srvr

# include the generated module, which in-turn includes our implementation code in `proto_tests_impl.jl`
# prepend with @everywhere when running a TProcessPoolServer on multiple Julia processors
#@everywhere include("gen-jl/proto_tests/proto_tests.jl")
include("gen-jl/srvcctrl/srvcctrl.jl");
include("gen-jl/proto_tests/proto_tests.jl");
import proto_tests: ProtoTestsProcessor, ProtoTestsClient, InvalidOperation, AllTypes, AllTypesDefault, TestEnum
import proto_tests: test_hello, test_exception, test_oneway, ping, test_enum, test_types, test_types_default
import srvcctrl: start_service, stop_service

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
@async try
    start_service(srvr)
catch ex
    println("Server stopped with $ex")
finally
    println("Stopped serving requests.")
end

# create a client instance with our choice of protocol and transport
clnt_transport = TSocket(19999)
#proto = TCompactProtocol(clnt_transport)
proto = TBinaryProtocol(clnt_transport)
clnt = ProtoTestsClient(proto)

function run_client()
    println("Transport: $(typeof(clnt_transport))")
    println("Protocol : $(typeof(proto))")
    println("Starting requests...")

    # open a connection
    open(clnt_transport)

    # invoke service and print the result
    println("\nCalling test_hello...")
    ret = test_hello(clnt, "Julia")
    println(ret)
    @test endswith(ret, "Julia")

    println("\nCalling test_exception...")
    try
        test_exception(clnt)
    catch ex
        println(ex)
        @test isa(ex, InvalidOperation)
        @test ex.oper == "test_exception"
    end

    println("\nCalling ping...")
    ping(clnt)

    println("\nCalling test_oneway...")
    test_oneway(clnt)

    println("\nCalling test_types_default...")
    ret = test_types_default(clnt, AllTypesDefault())
    println(ret)
    @test get_field(ret, :bool_val) == false
    @test get_field(ret, :byte_val) == 0x02
    @test get_field(ret, :i16_val) == 11
    @test get_field(ret, :i32_val) == 21
    @test get_field(ret, :i64_val) == 31
    @test get_field(ret, :double_val) == -10.1
    @test get_field(ret, :string_val) == "HELLO WORLD"

    v = get_field(ret, :map_val)
    @test length(v) == 2
    @test v[Int32(2)] == 40
    @test v[Int32(1)] == 20

    @test get_field(ret, :list_val) == Int16[11,12,13]
    v = get_field(ret, :set_val)
    @test length(v) == 3
    @test UInt8(13) in v
    @test UInt8(14) in v
    @test UInt8(15) in v

    println("\nCalling stop_service...")
    stop_service(clnt)

    # close connection
    close(clnt_transport)
end


println("Waiting for server to start...")
sleep(2)
run_client()
sleep(2)

