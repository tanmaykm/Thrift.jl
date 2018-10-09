struct _enum_TTransportExceptionTypes
    UNKNOWN::Int32
    NOT_OPEN::Int32
    ALREADY_OPEN::Int32
    TIMED_OUT::Int32
    END_OF_FILE::Int32
end

const TransportExceptionTypes = _enum_TTransportExceptionTypes(Int32(0), Int32(1), Int32(2), Int32(3), Int32(4))

struct TTransportException <: Exception
    typ::Int32
    message::AbstractString

    TTransportException(typ=TransportExceptionTypes.UNKNOWN, message::AbstractString="") = new(typ, message)
end


# TODO: Thrift SASL server transport
# Thrift SASL client transport
mutable struct TSASLClientTransport <: TTransport
    tp::TTransport
    mech::String
    callback::Function
    rbuff::IOBuffer
    wbuff::IOBuffer

    function TSASLClientTransport(tp::TTransport, mech::String=SASL_MECH_PLAIN, callback::Function=sasl_callback_default)
        validate_sasl_mech(mech)
        new(TFramedTransport(tp), mech, callback, PipeBuffer(), PipeBuffer())
    end
end

rawio(t::TSASLClientTransport)  = rawio(t.tp)
close(t::TSASLClientTransport)  = close(t.tp)
isopen(t::TSASLClientTransport) = isopen(t.tp)
flush(t::TSASLClientTransport)  = flush(t.tp)

read!(t::TSASLClientTransport, buff::Vector{UInt8}) = read!(t.tp, buff)
read(t::TSASLClientTransport, UInt8) = read(t.tp, UInt8)
function write(t::TSASLClientTransport, buff::Vector{UInt8})
    @logmsg("TSASLClientTransport buffering $(length(buff)) bytes")
    write(t.tp, buff)
end
function write(t::TSASLClientTransport, b::UInt8)
    @logmsg("TSASLClientTransport buffering 1 byte")
    write(t.tp, b)
end

function open(t::TSASLClientTransport)
    open(t.tp)
    sasl_negotiate(rawio(t), t.mech, t.callback)
end


# Thrift Framed Transport
mutable struct TFramedTransport <: TTransport
    tp::TTransport
    rbuff::IOBuffer
    wbuff::IOBuffer
    TFramedTransport(tp::TTransport) = new(tp, PipeBuffer(), PipeBuffer())
end
rawio(t::TFramedTransport)  = rawio(t.tp)
open(t::TFramedTransport)   = open(t.tp)
close(t::TFramedTransport)  = close(t.tp)
isopen(t::TFramedTransport) = isopen(t.tp)

readframesz(t::TFramedTransport) = _read_fixed(t.tp, UInt32(0), 4, true)
function readframe(t::TFramedTransport)
    @logmsg("TFramedTransport reading frame")
    sz = readframesz(t)
    @logmsg("TFramedTransport reading frame of $sz bytes")
    write(t.rbuff, read!(t.tp, Vector{UInt8}(undef,sz)))
    @logmsg("TFramedTransport read frame of $sz bytes")
    nothing
end

function read!(t::TFramedTransport, buff::Vector{UInt8})
    ntotal = length(buff)
    nread = 0

    while nread < ntotal
        navlb = bytesavailable(t.rbuff)
        nremain = ntotal - nread
        if navlb < nremain
            @logmsg("navlb: $navlb, nremain: $nremain, reading new frame")
            readframe(t)
            navlb = bytesavailable(t.rbuff)
        end
        nbuff = min(navlb, nremain)
        Base.read_sub(t.rbuff, buff, nread+1, nbuff)
        nread += nbuff
    end
    buff
end
function read(t::TFramedTransport, UInt8)
    navlb = bytesavailable(t.rbuff)
    if navlb == 0
        readframe(t)
    end
    return read(t.rbuff, UInt8)
end

function write(t::TFramedTransport, buff::Vector{UInt8})
    @logmsg("TFramedTransport buffering $(length(buff)) bytes")
    write(t.wbuff, buff)
end
function write(t::TFramedTransport, b::UInt8)
    @logmsg("TFramedTransport buffering 1 byte")
    write(t.wbuff, b)
end
function flush(t::TFramedTransport)
    szbuff = IOBuffer()
    navlb = bytesavailable(t.wbuff)
    @logmsg("sending data of length $navlb")
    _write_fixed(szbuff, UInt32(navlb), true)
    nbyt = write(t.tp, take!(szbuff))
    nbyt += write(t.tp, take!(t.wbuff))
    @logmsg("wrote frame of size $nbyt")
    flush(t.tp)
end


# Thrift Socket Transport
mutable struct TSocket <: TTransport
    host::AbstractString
    port::Integer

    io::TCPSocket

    TSocket(host::AbstractString, port::Integer) = new(host, port)
    TSocket(port::Integer) = TSocket("127.0.0.1", port)
end

mutable struct TServerSocket <: TServerTransport
    host::AbstractString
    port::Integer

    io::TCPServer

    TServerSocket(host::AbstractString, port::Integer) = new(host, port)
    TServerSocket(port::Integer) = TServerSocket("", port)
end

const TSocketBase = Union{TSocket, TServerSocket}

open(tsock::TServerSocket) = nothing
open(tsock::TSocket) = (!isopen(tsock) && (tsock.io = connect(tsock.host, tsock.port)); nothing)

listen(tsock::TServerSocket) = (tsock.io = isempty(tsock.host) ? listen(tsock.port) : listen(parseip(tsock.host), tsock.port); nothing)
function accept(tsock::TServerSocket)
    accsock = TSocket(tsock.host, tsock.port)
    accsock.io = accept(tsock.io)
    accsock
end

close(tsock::TSocketBase) = (isopen(tsock.io) && close(tsock.io); nothing)
rawio(tsock::TSocketBase) = tsock.io
read!(tsock::TSocketBase, buff::Vector{UInt8}) = read!(tsock.io, buff)
read(tsock::TSocketBase, UInt8) = read(tsock.io, UInt8)
write(tsock::TSocketBase, buff::Vector{UInt8}) = write(tsock.io, buff)
write(tsock::TSocketBase, b::UInt8) = write(tsock.io, b)
flush(tsock::TSocketBase)   = flush(tsock.io)
isopen(tsock::TSocketBase)  = (isdefined(tsock, :io) && isreadable(tsock.io) && iswritable(tsock.io))

# Thrift Memory Transport
mutable struct TMemoryTransport <: TTransport
    buff::IOBuffer

    TMemoryTransport() = new(PipeBuffer())
    TMemoryTransport(buff::Array{UInt8}) = new(PipeBuffer(buff))
end

rawio(t::TMemoryTransport)  = t.buff
open(t::TMemoryTransport)   = nothing
close(t::TMemoryTransport)  = nothing
isopen(t::TMemoryTransport) = true
flush(t::TMemoryTransport)  = nothing
read!(t::TMemoryTransport, buff::Vector{UInt8}) = read!(t.buff, buff)
read(t::TMemoryTransport, UInt8) = read(t.buff, UInt8)
write(t::TMemoryTransport, buff::Vector{UInt8}) = write(t.buff, buff)
write(t::TMemoryTransport, b::UInt8) = write(t.buff, b)

# Thrift File IO Transport
mutable struct TFileTransport <: TTransport
    handle::IO
end

rawio(t::TFileTransport)  = t.handle
open(t::TFileTransport)   = nothing
close(t::TFileTransport)  = nothing
isopen(t::TFileTransport) = true
flush(t::TFileTransport)  = flush(t.handle)
read!(t::TFileTransport, buff::Vector{UInt8}) = read!(t.handle, buff)
read(t::TFileTransport, UInt8) = read(t.handle, UInt8)
write(t::TFileTransport, buff::Vector{UInt8}) = write(t.handle, buff)
write(t::TFileTransport, b::UInt8) = write(t.handle, b)
