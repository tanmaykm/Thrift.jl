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
#        handle(p.tp, ThriftHandler("calculate", p, _calculate, CalculatorInput, CalculatorOutput))
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
    ThriftProcessor() = new(Dict{String, Function}())
end

handle(p::ThriftProcessor, handler::ThriftHandler) = (p.handlers[handler.name] = handler; nothing)

function process(p::ThriftProcessor, inp::TProtocol, outp::TProtocol)
    (name, typ, seqid) = readMessageBegin(inp)
    if !haskey(p.handlers, name)
        skip(inp, TSTRUCT)
        readMessageEnd(inp)
        x = TApplicationException(ApplicationExceptionType.UNKNOWN_METHOD, "Unknown function $name")
        writeMessageBegin(name, MessageType.EXCEPTION, seqid)
        write(outp, x)
        writeMessageEnd(outp)
        flush(outp.t)
        return
    end

    handler = p.handlers[name]
    instruct = read(inp, handler.intyp)
    readMessageEnd(inp)
    outstruct = handler.fn(instruct)

    writeMessageBegin(outp, name, TSTRUCT, seqid)
    write(outp, outstruct)
    writeMessageEnd(outp)
    flush(outp.t)
end

