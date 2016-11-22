testdir = dirname(@__FILE__)
ENV["PATH"] = join([joinpath(dirname(@__FILE__), "deps", "bin"), ENV["PATH"]], is_windows() ? ";" : ":")

const RUN_ENV = isless(Base.VERSION, v"0.5.0-") ? ["$n=$v" for (n,v) in ENV] : ENV

run(Cmd(`thrift -gen jl srvcctrl.thrift`, env=RUN_ENV))
run(Cmd(`thrift -gen jl proto_tests.thrift`, env=RUN_ENV))
println("Compiled IDLs...")

cp(joinpath(testdir, "srvcctrl_impl.jl"), joinpath(testdir, "gen-jl", "srvcctrl", "srvcctrl_impl.jl"); remove_destination=true)
cp(joinpath(testdir, "proto_tests_impl.jl"), joinpath(testdir, "gen-jl", "proto_tests", "proto_tests_impl.jl"); remove_destination=true)
println("Added service implementations...")
