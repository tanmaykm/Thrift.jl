module TestGen
using Thrift
using Test

const testdir = dirname(@__FILE__)

function generate()
    @testset "code generation" begin
        @testset "basic" begin
            # generate code
            for (proto_name,type_name) in (("srvcctrl","ServiceControl"), ("proto_tests","ProtoTests"))
                Thrift.generate(proto_name * ".thrift")
                for suffix in ("_constants.jl", "_types.jl", ".jl")
                    @test isfile(joinpath(testdir, "gen-jl", proto_name, proto_name * suffix))
                end
                @test isfile(joinpath(testdir, "gen-jl", proto_name, type_name * ".jl"))
            end

            # add service implementations
            cp(joinpath(testdir, "srvcctrl_impl.jl"), joinpath(testdir, "gen-jl", "srvcctrl", "srvcctrl_impl.jl"); force=true)
            cp(joinpath(testdir, "proto_tests_impl.jl"), joinpath(testdir, "gen-jl", "proto_tests", "proto_tests_impl.jl"); force=true)
        end
        @testset "service method disambiguation" begin
            Thrift.generate("disambiguate_svc_method.thrift")
            touch(joinpath(testdir, "gen-jl", "disambiguate_svc_method", "disambiguate_svc_method_impl.jl"))
            include(joinpath(testdir, "gen-jl", "disambiguate_svc_method", "disambiguate_svc_method.jl"))
            @test disambiguate_svc_method.hello_to_args_Other !== disambiguate_svc_method.hello_to_args_SayHello
        end
    end
end

generate()

end # module TestGen
