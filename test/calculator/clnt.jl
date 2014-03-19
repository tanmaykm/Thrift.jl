using Thrift
import Thrift.process, Thrift.meta

include("gen-jl/arithmetic/constants.jl");
include("gen-jl/arithmetic/types.jl");
include("gen-jl/arithmetic/Calc.jl");

function calcclnt(niter::Int)
    clnt_transport = TSocket(9999)
    proto = TBinaryProtocol(clnt_transport)

    clnt = CalcClient(proto)

    println("opening connection. $(clnt_transport)")
    open(clnt_transport)
    println("opened connection. $(clnt_transport)")
    nops = length(OPS)
    for idx in 1:niter
        op = string(OPS[int((nops-1)*rand())+1])
        p1 = int32(100*rand())
        p2 = int32(100*rand())
        res = calculate(clnt, op, p1, p2)
        println("$op ( $p1, $p2 ) = $res")
    end
    close(clnt_transport)
end

for idx in 1:5
    calcclnt(10)
end


