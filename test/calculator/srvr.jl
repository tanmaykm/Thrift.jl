using Thrift
import Thrift.process, Thrift.meta

include("gen-jl/floatops/floatops_constants.jl");
include("gen-jl/floatops/floatops_types.jl");
include("gen-jl/floatops/FloatCalc.jl");

include("gen-jl/arithmetic/arithmetic_constants.jl");
include("gen-jl/arithmetic/arithmetic_types.jl");
include("gen-jl/arithmetic/Calc.jl");

function calculate(oper::AbstractString, p1::Int32, p2::Int32) 
    ret = (eval(symbol(oper)))(p1, p2)
    if ret > (2^31 - 1) 
        ex = InvalidOperation()
        ex.oper = "$oper($p1, $p2) overflows"
        throw(ex)
    end
    ret
end

function float_calculate(oper::AbstractString, p1::Float64, p2::Float64)
    ret = (eval(symbol(oper)))(p1, p2)
    if ret > (2^63 - 1) 
        ex = InvalidFloatOperation()
        ex.oper = "$oper($p1, $p2) overflows"
        throw(ex)
    end
    ret
end

function calcsrvr()
    cp = CalcProcessor()
    srvr_transport = TServerSocket(19999)
    srvr = TSimpleServer(srvr_transport, cp, x->x, x->TBinaryProtocol(x), x->x, x->TBinaryProtocol(x))
    #srvr = TSimpleServer(srvr_transport, cp, x->x, x->TCompactProtocol(x), x->x, x->TCompactProtocol(x))
    println("starting julia server...")
    serve(srvr)
    println("server stopped")
end 

calcsrvr()

