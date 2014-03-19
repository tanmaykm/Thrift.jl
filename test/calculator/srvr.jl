using Thrift
import Thrift.process, Thrift.meta

include("gen-jl/arithmetic/constants.jl");
include("gen-jl/arithmetic/types.jl");
include("gen-jl/arithmetic/Calc.jl");

calculate(oper::String, p1::Int32, p2::Int32) = convert(Int32, (eval(symbol(oper)))(p1, p2))

function calcsrvr()
    cp = CalcProcessor()
    srvr_transport = TServerSocket(9999)
    srvr = TSimpleServer(srvr_transport, cp, x->x, x->TBinaryProtocol(x), x->x, x->TBinaryProtocol(x))
    println("starting julia server...")
    serve(srvr)
    println("server stopped")
end 
    
calcsrvr()

