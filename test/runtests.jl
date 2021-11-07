using Test

if Sys.iswindows()
    @info "No tests enabled for for your platform by default."
else
    @testset "all thrift tests" begin
        @info("Generating code")
        include("gen.jl")
        @info("Running client server tests")
        include("clntsrvr.jl")

        @info("Running protocol and transport tests")
        include("memtransport_tests.jl")
        include("filetransport_tests.jl")
        include("headertransport_tests.jl")
        include("utils_tests.jl")
    end
end
