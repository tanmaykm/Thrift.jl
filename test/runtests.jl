if Sys.iswindows()
    @info "No tests enabled for for your platform by default."
else
    include("gen.jl")

    ENV["TEST_SRVR_ASYNC"] = "true"
    include("srvr.jl")
    include("clnt.jl")

    include("memtransport_tests.jl")
    include("filetransport_tests.jl")
    include("utils_tests.jl")
end
