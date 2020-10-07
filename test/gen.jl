module TestGen
using Thrift
using Test

const testdir = dirname(@__FILE__)

function generate()
    @testset "code generation" begin
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
end

generate()

end # module TestGen