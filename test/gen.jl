testdir = dirname(@__FILE__)
ENV["PATH"] = join([joinpath(dirname(testdir), "deps", "usr", "bin"), ENV["PATH"]], Sys.iswindows() ? ";" : ":")

run(Cmd(`thrift -gen jl srvcctrl.thrift`, env=ENV))
run(Cmd(`thrift -gen jl proto_tests.thrift`, env=ENV))
println("Compiled IDLs...")

cp(joinpath(testdir, "srvcctrl_impl.jl"), joinpath(testdir, "gen-jl", "srvcctrl", "srvcctrl_impl.jl"); force=true)
cp(joinpath(testdir, "proto_tests_impl.jl"), joinpath(testdir, "gen-jl", "proto_tests", "proto_tests_impl.jl"); force=true)
println("Added service implementations...")
