using Compat

include("gen.jl")

if VERSION < v"0.7.0-alpha"
    macro isdefined(x)
    end
end

ENV["TEST_SRVR_ASYNC"] = "true"
include("srvr.jl")
include("clnt.jl")

include("memtransport_tests.jl")
include("filetransport_tests.jl")
include("utils_tests.jl")
