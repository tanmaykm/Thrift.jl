using Thrift
using Test

import Thrift.process, Thrift.meta

# include the generated module, which in-turn includes our implementation code in `proto_tests_impl.jl`
# prepend with @everywhere when running a TProcessPoolServer on multiple Julia processors
@isdefined(srvcctrl) || include("gen-jl/srvcctrl/srvcctrl.jl");
@isdefined(proto_tests) || include("gen-jl/proto_tests/proto_tests.jl");

import .proto_tests: ProtoTestsClient, InvalidOperation, AllTypes, AllTypesDefault, TestEnum
import .proto_tests: test_hello, test_exception, test_oneway, ping, test_enum, test_types, test_types_default
import .srvcctrl: start_service, stop_service

# create a client instance with our choice of protocol and transport
# clnt_transport = TSocket(19999)
# proto = TCompactProtocol(clnt_transport)
# proto = TBinaryProtocol(clnt_transport)
clnt_transport = THeaderTransport(TSocket(19999))
proto = THeaderProtocol(TBinaryProtocol(clnt_transport))
clnt = ProtoTestsClient(proto)

function run_client()
    @info("client transport: $(typeof(clnt_transport))")
    @info("client protocol : $(typeof(proto))")
    @info("client starting requests...")

    # open a connection
    open(clnt_transport)

    @testset "simple calls" begin
        # invoke service and print the result
        @info("client calling test_hello")
        ret = test_hello(clnt, "Julia")
        #println(ret)
        @test endswith(ret, "Julia")

        @info("client calling test_exception")
        try
            test_exception(clnt)
        catch ex
            #println(ex)
            @test isa(ex, InvalidOperation)
            @test ex.oper == "test_exception"
        end

        @info("client calling ping")
        ping(clnt)

        @info("client calling test_oneway")
        test_oneway(clnt)
    end

    @testset "types call test" begin
        @info("client calling test_types_default")
        ret = test_types_default(clnt, AllTypesDefault())
        #println(ret)
        @test ret.bool_val == false
        @test ret.byte_val == 0x02
        @test ret.i16_val == 11
        @test ret.i32_val == 21
        @test ret.i64_val == 31
        @test ret.double_val == -10.1
        @test ret.string_val == "HELLO WORLD"

        v = ret.map_val
        @test length(v) == 2
        @test v[Int32(2)] == 40
        @test v[Int32(1)] == 20

        @test ret.list_val == Int16[11,12,13]
        v = ret.set_val
        @test length(v) == 3
        @test UInt8(13) in v
        @test UInt8(14) in v
        @test UInt8(15) in v
    end

    @info("client calling stop_service")
    stop_service(clnt)

    # close connection
    close(clnt_transport)
end

@info("client waiting for server to start...")
sleep(2)
run_client()
sleep(2)
