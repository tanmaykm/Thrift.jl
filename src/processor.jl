##
# The default processor core.

mutable struct ThriftHandler{I,O}
    name::AbstractString
    fn::Function
    intyp::Type{I}
    outtyp::Type{O}
end

mutable struct ThriftProcessor
    handlers::Dict{AbstractString, ThriftHandler}
    use_spawn::Bool
    extends::ThriftProcessor
    ThriftProcessor() = (o=new(); o.use_spawn=false; o.handlers=Dict{AbstractString, ThriftHandler}(); o)
end

handle(p::ThriftProcessor, handler::ThriftHandler) = (p.handlers[handler.name] = handler; nothing)
extend(p::ThriftProcessor, extends::ThriftProcessor) = (setfield!(p, :extends, extends); nothing)
distribute(p::ThriftProcessor, use_spawn::Bool=true) = (setfield!(p, :use_spawn, use_spawn); nothing)

function _reply(outp::TProtocol, name::AbstractString, seqid::Int32, mtyp::Int32, m::Any)
    @debug("_reply", name, seqid, m)
    writeMessageBegin(outp, name, mtyp, seqid)
    write(outp, m)
    writeMessageEnd(outp)
    flush(outp.t)
    nothing
end

_exception(extyp::Int32, exmsg::AbstractString, outp::TProtocol, name::AbstractString, seqid::Int32) = _reply(outp, name, seqid, MessageType.EXCEPTION, TApplicationException(; typ=extyp, message=exmsg))

function process(p::ThriftProcessor, inp::TProtocol, outp::TProtocol)
    @debug("process begin")
    (name, typ, seqid) = readMessageBegin(inp)

    haskey(p.handlers, name) && (return _process(p, inp, outp, name, typ, seqid))

    isdefined(p, :extends) && (return _process(p.extends, inp, outp, name, typ, seqid))

    skip(inp, TSTRUCT)
    readMessageEnd(inp)
    _exception(ApplicationExceptionType.UNKNOWN_METHOD, "Unknown function $name", outp, name, seqid)
end

function _process(p::ThriftProcessor, inp::TProtocol, outp::TProtocol, name::AbstractString, typ::Int32, seqid::Int32)
    handler = p.handlers[name]
    @debug("_process: reading instruct", type=handler.intyp)
    instruct = read(inp, handler.intyp)
    readMessageEnd(inp)
    @debug("_process: calling handler function")
    if p.use_spawn
        outstruct = fetch(@spawn handler.fn(instruct))
    else
        outstruct = handler.fn(instruct)
    end
    @debug("_process: out of handler function", outstruct)
    if !isa(outstruct, handler.outtyp)
        _exception(ApplicationExceptionType.MISSING_RESULT, "Invalid return type. Expected $(handler.outtyp). Got $(typeof(outstruct))", outp, name, seqid)
        return
    end
    isa(outstruct, Nothing) || _reply(outp, name, seqid, MessageType.REPLY, outstruct)
end
