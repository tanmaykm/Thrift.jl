##
# The default processor core.
#
# For a service:
# service Calculator {
#     i32 calculate(1:i32 logid, 2:Work w) throws (1:InvalidOperation ouch)
# }
#
#
# Generated server processor would look like:
#
# type CalculatorInput
#     logid::TI32
# end
# type CalculatorOutput
#     w::Work
# end
# type CalculatorProcessor <: TProcessor
#    tp::ThriftProcessor
#    function CalculatorProcessor()
#        p = new(ThriftProcessor())
#        handle(p.tp, ThriftHandler("calculate", _calculate, CalculatorInput, CalculatorOutput))
#        p
#    end
#    _calculate(inp::CalculatorInput) = CalculatorOutput(calculate(inp.logid))
# end
# process(p::CalculatorProcessor, inp::TProtocol, outp::TProtocol) = process(p.tp, inp, outp)
#
#
# Generated client code would look like:
#
# type CalculatorClient
#    p::TProtocol
#    seqid::Int32
# end
# function calculate(c::CalculatorClient, logid::TI32)
#    p = c.p
#    c.seqid = (c.seqid < (2^31-1)) ? (c.seqid+1) : 0
#    writeMessageBegin(p, "calculate", TMessageType.CALL, c.seqid)
#    write(p, CalculatorInput(logid))
#    writeMessageEnd(p)
#    flush(p.t)
#    
#    (fname, mtype, rseqid) = readMessageBegin(p)
#    (mtype == TMessageType.EXCEPTION) && throw(read(p, TSTRUCT, TApplicationException()))
#    outp = read(p, TSTRUCT, CalculatorOutput())
#    readMessageEnd(p)
#    (rseqid != c.seqid) && throw(TApplicationException(ApplicationExceptionType.BAD_SEQUENCE_ID, "respose sequese id $rseqid did not match request ($(c.seqid))"))
#    isdefined(p, :w) && return(getfield(p, :w))
#    throw(TApplicationException(ApplicationExceptionType.MISSING_RESULT, "retrieve failed: unknown result")
# end
#
#
# Server implementation would look like:
#
# Client implementation would look like:
#
#


type ThriftHandler
    name::String
    fn::Function
    intyp::Type
    outtyp::Type
end

type ThriftProcessor
    handlers::Dict{String, ThriftHandler}
    ThriftProcessor() = new(Dict{String, ThriftHandler}())
end

handle(p::ThriftProcessor, handler::ThriftHandler) = (p.handlers[handler.name] = handler; nothing)

function raise_exception(extyp::Int32, exmsg::String, outp::TProtocol, name::String, seqid::Int32)
    x = TApplicationException(extyp, exmsg)
    writeMessageBegin(outp, name, MessageType.EXCEPTION, seqid)
    write(outp, x)
    writeMessageEnd(outp)
    flush(outp.t)
end

function process(p::ThriftProcessor, inp::TProtocol, outp::TProtocol)
    logmsg("process begin")
    (name, typ, seqid) = readMessageBegin(inp)
    if !haskey(p.handlers, name)
        skip(inp, TSTRUCT)
        readMessageEnd(inp)
        raise_exception(ApplicationExceptionType.UNKNOWN_METHOD, "Unknown function $name", outp, name, seqid)
        return
    end

    handler = p.handlers[name]
    instruct = read(inp, TSTRUCT, instantiate(handler.intyp))
    readMessageEnd(inp)
    logmsg("process calling handler function")
    outstruct = handler.fn(instruct)
    logmsg("process out of handler function. return val: $outstruct")
    if !isa(outstruct, handler.outtyp)
        raise_exception(ApplicationExceptionType.MISSING_RESULT, "Invalid return type. Expected $(handler.outtyp). Got $(typeof(outstruct))", outp, name, seqid)
        return
    end

    writeMessageBegin(outp, name, MessageType.REPLY, seqid)
    write(outp, outstruct)
    writeMessageEnd(outp)
    flush(outp.t)
end

