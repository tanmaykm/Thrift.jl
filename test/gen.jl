testdir = dirname(@__FILE__)

run(`thrift -gen jl srvcctrl.thrift`)
run(`thrift -gen jl proto_tests.thrift`)
println("Compiled IDLs...")
cp(joinpath(testdir, "srvcctrl_impl.jl"), joinpath(testdir, "gen-jl", "srvcctrl", "srvcctrl_impl.jl"); remove_destination=true)
cp(joinpath(testdir, "proto_tests_impl.jl"), joinpath(testdir, "gen-jl", "proto_tests", "proto_tests_impl.jl"); remove_destination=true)
println("Added service implementations...")
