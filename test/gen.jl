using Thrift

testdir = dirname(@__FILE__)

Thrift.generate("srvcctrl.thrift")
Thrift.generate("proto_tests.thrift")
println("Compiled IDLs...")

cp(joinpath(testdir, "srvcctrl_impl.jl"), joinpath(testdir, "gen-jl", "srvcctrl", "srvcctrl_impl.jl"); force=true)
cp(joinpath(testdir, "proto_tests_impl.jl"), joinpath(testdir, "gen-jl", "proto_tests", "proto_tests_impl.jl"); force=true)
println("Added service implementations...")
