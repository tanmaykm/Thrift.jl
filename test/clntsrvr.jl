module TestClntSrvr

using Test

@testset "thrift client server" begin
    ENV["TEST_SRVR_ASYNC"] = "true"
    include("srvr.jl")
    include("clnt.jl")
end

end # module TestClntSrvr