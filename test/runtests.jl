include("gen.jl")

ENV["TEST_SRVR_ASYNC"] = "true"
include("srvr.jl")
include("clnt.jl")

include("memtransport_tests.jl")
