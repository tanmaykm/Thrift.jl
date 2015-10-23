using Thrift
import Thrift.process, Thrift.meta

include("gen-jl/floatops/floatops_constants.jl");
include("gen-jl/floatops/floatops_types.jl");
include("gen-jl/floatops/FloatCalc.jl");

include("gen-jl/arithmetic/arithmetic_constants.jl");
include("gen-jl/arithmetic/arithmetic_types.jl");
include("gen-jl/arithmetic/Calc.jl");

function calcclnt(niter::Int)
    clnt_transport = TSocket(19999)
    #proto = TCompactProtocol(clnt_transport)
    proto = TBinaryProtocol(clnt_transport)

    clnt = CalcClient(proto)

    println("opening connection. $(clnt_transport)")
    open(clnt_transport)
    println("opened connection. $(clnt_transport)")
    nops = length(OPS)
    for idx in 1:niter
        try
            op = string(OPS[round(Int, (nops-1)*rand())+1])
            p1 = round(Int32, 100*rand())
            p2 = round(Int32, 100*rand())
            res = calculate(clnt, op, p1, p2)
            println("$op ( $p1, $p2 ) = $res")
        catch ex
            !isa(ex, InvalidOperation) && rethrow()
            println(ex.oper)
        end
    end
    close(clnt_transport)
    println("closed connection. $(clnt_transport)")
end

function floatcalcclnt(niter::Int)
    clnt_transport = TSocket(19999)
    #proto = TCompactProtocol(clnt_transport)
    proto = TBinaryProtocol(clnt_transport)

    clnt = CalcClient(proto)

    println("opening connection. $(clnt_transport)")
    open(clnt_transport)
    println("opened connection. $(clnt_transport)")
    nops = length(FLOAT_OPS)
    for idx in 1:niter
        try
            m = (idx > 3) ? 50 : 8
            op = string(FLOAT_OPS[round(Int, (nops-1)*rand())+1])
            p1 = (2^m) * randn()
            p2 = (2^m) * randn()
            res = float_calculate(clnt, op, p1, p2)
            println("$op ( $p1, $p2 ) = $res")
        catch ex
            !isa(ex, InvalidFloatOperation) && rethrow()
            println(ex.oper)
        end
    end
    close(clnt_transport)
    println("closed connection. $(clnt_transport)")
end

for idx in 1:5
    calcclnt(10)
    floatcalcclnt(10)
end


