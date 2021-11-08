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
    @debug("TSASLClientTransport buffering bytes", len=length(buff))
    write(t.tp, buff)
end
function write(t::TSASLClientTransport, b::UInt8)
    @debug("TSASLClientTransport buffering 1 byte")
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
    @debug("TFramedTransport reading frame")
    sz = readframesz(t)
    @debug("TFramedTransport reading frame", sz)
    write(t.rbuff, read!(t.tp, Vector{UInt8}(undef,sz)))
    @debug("TFramedTransport read frame", sz)
    nothing
end

function read!(t::TFramedTransport, buff::Vector{UInt8})
    ntotal = length(buff)
    nread = 0

    while nread < ntotal
        navlb = bytesavailable(t.rbuff)
        nremain = ntotal - nread
        if navlb < nremain
            @debug("reading new frame", navlb, nremain)
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
    @debug("TFramedTransport buffering bytes", len=length(buff))
    write(t.wbuff, buff)
end
function write(t::TFramedTransport, b::UInt8)
    @debug("TFramedTransport buffering 1 byte")
    write(t.wbuff, b)
end
function flush(t::TFramedTransport)
    szbuff = IOBuffer()
    navlb = bytesavailable(t.wbuff)
    @debug("sending data", navlb)
    _write_fixed(szbuff, UInt32(navlb), true)
    nbyt = write(t.tp, take!(szbuff))
    nbyt += write(t.tp, take!(t.wbuff))
    @debug("wrote frame", nbyt)
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

function open(tsock::TSocket)
    if !isopen(tsock)
        tsock.io = connect(tsock.host, tsock.port)
    end
    return nothing
end

function listen(tsock::TServerSocket)
    tsock.io = if isempty(tsock.host)
        listen(tsock.port)
    else
        ip = occursin(":", tsock.host) ? IPv6(tsock.host) : IPv4(tsock.host)
        listen(ip, tsock.port)
    end
    return nothing
end

function accept(tsock::TServerSocket)
    accsock = TSocket(tsock.host, tsock.port)
    accsock.io = accept(tsock.io)
    accsock
end

close(tsock::TSocketBase) = (isopen(tsock.io) && close(tsock.io); nothing)
rawio(tsock::TSocketBase) = tsock.io

function read!(tsock::TSocketBase, buff::Vector{UInt8})
    result = read!(tsock.io, buff)
    @debug "TSocketBase.read!" tohex(buff)
    return result
end

function read(tsock::TSocketBase, sz::Union{Integer,Type{<:Unsigned}})
    result = read(tsock.io, sz)
    @debug "TSocketBase.read" tohex(result)
    return result
end

function write(tsock::TSocketBase, buff::Vector{UInt8})
    @debug "TSocketBase.write" tohex(buff)
    return write(tsock.io, buff)
end

function write(tsock::TSocketBase, b::UInt8)
    @debug "TSocketBase.write" b
    return write(tsock.io, b)
end

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

# ---------------------------------------------------------------------
# THeader transport
#
# The following code is largely adapted from the Python implementation
# of the THeader transport, with the exception that it does not include
# any code that handles the deprecated/unframed protocol here.
# ---------------------------------------------------------------------

# Define constants

module ProtocolType
    const BINARY = 0
    const COMPACT = 2
    const UNKNOWN = -1
end
using .ProtocolType

module ClientType
    const HEADER = 0
    const FRAMED_DEPRECATED = 1
    const UNFRAMED_DEPRECATED = 2
    const HTTP_SERVER = 3
    const HTTP_CLIENT = 4
    const FRAMED_COMPACT = 5
    const HTTP_GET = 7
    const UNKNOWN = 8
    const UNFRAMED_COMPACT_DEPRECATED = 9
end
using .ClientType

module TransformType
    const NONE = 0x00
    const ZLIB = 0x01
    const HMAC = 0x02
    const SNAPPY = 0x03
    const QLZ = 0x04
    const ZSTD = 0x05
end
using .TransformType

module InfoType
    const NORMAL = 1
    const PERSISTENT = 2
end
using .InfoType

module Magic
    const HEADER_MAGIC = 0x0FFF0000
    const HEADER_MASK = 0xFFFF0000
    const FLAGS_MASK = 0x0000FFFF
    const HTTP_SERVER_MAGIC = 0x504F5354  # POST
    const HTTP_CLIENT_MAGIC = 0x48545450  # HTTP
    const HTTP_GET_CLIENT_MAGIC = 0x47455420  # GET
    const HTTP_HEAD_CLIENT_MAGIC = 0x48454144  # HEAD
    const BIG_FRAME_MAGIC = 0x42494746  # BIGF
    const MAX_FRAME_SIZE = 0x3FFFFFFF
    const PACKED_HEADER_MAGIC = [0x0f, 0xff]
end
using .Magic

module HeaderKeys
    const CLIENT_METADATA = "client_metadata"
end
using .HeaderKeys

"""
    THeaderTransport{TransportType <: TTransport} <: TTransport

THeaderTransport is a transport itself but it also wraps another transport.
For examples, `THeaderTransport{TSocket}` or `THeaderTransport{TMemory}`.
"""
Base.@kwdef mutable struct THeaderTransport{TransportType <: TTransport} <: TTransport
    transport::TransportType
    rbuf = PipeBuffer()
    # rbuf_frame = false
    wbuf = PipeBuffer()
    seqid = 0
    flags = 0
    read_transforms = Int[]
    write_transforms = Int[]
    proto_id = ProtocolType.UNKNOWN
    client_type = ClientType.HEADER
    read_headers = Dict{String,String}()
    read_persistent_headers = Dict{String,String}()
    write_headers = Dict{String,String}()
    write_persistent_headers = Dict{String,String}()
    first_request = true
end

rawio(t::THeaderTransport)  = rawio(t.transport)
open(t::THeaderTransport)   = open(t.transport)
close(t::THeaderTransport)  = close(t.transport)
isopen(t::THeaderTransport) = isopen(t.transport)

read!(t::THeaderTransport, buff::Vector{UInt8}) = read!(t.rbuf, buff)

function read(t::THeaderTransport, sz::Integer)
    data = read(t.rbuf, sz)
    len = length(data)
    len == sz && return data
    remaining = sz - len
    read_frame!(t)
    return append!(data, take!(t.rbuf, remaining))
end

function read(t::THeaderTransport, DT::DataType)
    navlb = bytesavailable(t.rbuf)
    if navlb == 0
        read_frame!(t)
    end
    return read(t.rbuf, DT)
end

function read_frame!(t::THeaderTransport)
    word1 = read(t.transport, 4)
    sz = ntoh(reinterpret(Int32, word1)[1])
    proto_id = word1[1]
    @debug "read_frame!" tohex(word1) sz proto_id

    proto_id in (BINARY_PROTOCOL_ID, COMPACT_PROTOCOL_ID) &&
        throw(TTransportException("Unframed protocols are deprecated already"))
    sz == Magic.HTTP_SERVER_MAGIC &&
        throw(TTransportException("HTTP server not supported"))

    if sz == Magic.BIG_FRAME_MAGIC
        sz = ntoh(reinterpret(UInt64, read(t.transport, 8))[1])
    end
    magic = read(t.transport, 2)
    proto_id = magic[1]
    proto_id in (BINARY_PROTOCOL_ID, COMPACT_PROTOCOL_ID) &&
        throw(TTransportException("Header protocol expected rather than binary/compact"))

    if magic == Magic.PACKED_HEADER_MAGIC
        @debug "Yay, found header magic" tohex(magic)
        t.client_type = ClientType.HEADER
        # TODO implement _frame_size_check
        # flags(2), seq_id(4), header_size(2)
        n_header_meta = read(t.transport, 8)
        t.flags = ntoh(reinterpret(UInt16, n_header_meta[1:2])[1])
        t.seqid = ntoh(reinterpret(UInt32, n_header_meta[3:6])[1])
        header_size = ntoh(reinterpret(UInt16, n_header_meta[7:8])[1])
        remaining = sz - 10
        @debug "read_frame!" tohex(proto_id) tohex(n_header_meta) tohex(t.flags) tohex(t.seqid) header_size remaining
        buf = IOBuffer()
        write(buf, magic)
        write(buf, n_header_meta)
        write(buf, read(t.transport, remaining))
        seek(buf, 10)
        peek_buffer(buf, "read_frame! buf")
        read_header_format!(t, remaining, header_size, buf)
    else
        t.client_type = ClientType.UNKNOWN
        throw(TTransportException("Client type $(t.client_type) not supported on server"))
    end
    return nothing
end

# NOTE: buf position must be at the beginniing of header meta
function read_header_format!(t::THeaderTransport, sz::Integer, header_size::Integer, buf::IOBuffer)
    t.read_transforms = Int[]  # clear out previous transformations (TODO: needed?)
    header_size_in_bytes = header_size * 4
    header_size_in_bytes <= sz ||
        throw(TTransportException("Header size $(header_size_in_bytes) is larger than frame size $sz"))

    end_header = position(buf) + header_size_in_bytes
    t.proto_id = readVarint(buf)
    num_headers = readVarint(buf)
    @debug "read_header_format!" t.proto_id num_headers

    for _ in 1:num_headers
        trans_id = readVarint(buf)
        if trans_id in (TransformType.ZLIB, TransformType.ZSTD) # TODO: snappy
            insert!(t.read_transforms, 1, trans_id)
        else
            throw(TTransportException("Unsupport transformation: $trans_id"))
        end
    end

    empty!(t.read_headers)
    while position(buf) < end_header
        info_id = readVarint(buf)
        if info_id === InfoType.NORMAL
            read_info_headers(buf, end_header, t.read_headers)
        elseif info_id === InfoType.PERSISTENT
            read_info_headers(buf, end_header, t.read_persistent_headers)
        else
            break # Unknown
        end
    end
    merge!(t.read_headers, t.read_persistent_headers)

    # Read payload, untransform it, and place it in rbuf
    seek(buf, end_header)
    @debug "read_header_format! seeking to end_header" end_header
    payload = read(buf, sz - header_size)
    @debug "read_header_format!" tohex(payload)
    t.rbuf = PipeBuffer(untransform(t, payload))
end

function read_info_headers(buf::IOBuffer, end_header::Integer, dct::AbstractDict{<:String,<:String})
    num_keys = readVarint(buf)
    for _ in 1:num_keys
        key = read_string(buf, end_header)
        val = read_string(buf, end_header)
        dct[key] = val
    end
end

function read_string(buf::IOBuffer, end_header::Integer)
    str_sz = readVarint(buf)
    position(buf) + str_sz > end_header &&
        throw(TTransportException("String read too big: $str_sz, past end_header=$end_header"))
    return String(read(buf, str_sz))
end

write(t::THeaderTransport, buff::Vector{UInt8}) = write(t.wbuf, buff)
write(t::THeaderTransport, b::UInt8) = write(t.wbuf, b)

function transform(t::THeaderTransport, data::Vector{UInt8})
    for trans_id in t.write_transforms
        if trans_id == TransformType.ZLIB
            data = transform_data(ZlibCompressor, data)
        elseif trans_id == TransformType.ZSTD
            data = transform_data(ZstdCompressor, data)
        else
            throw(TTransportException("Unsupported transformation: $trans_id"))
        end
    end
    return data
end

function untransform(t::THeaderTransport, data::Vector{UInt8})
    for trans_id in t.read_transforms
        if trans_id == TransformType.ZLIB
            data = transform_data(ZlibDecompressor, data)
        elseif trans_id == TransformType.ZSTD
            data = transform_data(ZstdDecompressor, data)
        else
            throw(TTransportException("Unsupported transformation: $trans_id"))
        end
    end
    return data
end

function transform_data(codec, data::Vector{UInt8})
    codec_processor = codec()
    TranscodingStreams.initialize(codec_processor)
    return transcode(codec_processor, data)
end

function flush(t::THeaderTransport, oneway=false)
    # Flush write buffer (wbuf) which contains the payload
    wout = transform(t, take!(t.wbuf))
    wsz = length(wout)

    # Create a new IO buffer to hold the entire message including header
    buf = make_header_message(t, wout, wsz)

    message_length_offset = wsz < Magic.MAX_FRAME_SIZE ? 4 : 12
    frame_size = bytesavailable(buf) - message_length_offset
    # TODO implement frame_size_check

    peek_buffer(buf, "Header Message")
    write(t.transport, take!(buf))

    if oneway
        flush_oneway(t.transport)  # TODO implement oneway
    else
        flush(t.transport)
    end
end

function make_header_message(
    t::THeaderTransport,
    wout::Vector{UInt8},
    wsz::Integer
)
    buf = PipeBuffer()

    # Append client metadata header for the first request
    if t.first_request
        t.first_request = false
        t.write_headers[HeaderKeys.CLIENT_METADATA] = """{"agent":"Julia THeaderTransport"}"""
    end

    # 1. Transform meta
    transform_data = PipeBuffer()
    for trans_id in t.write_transforms
        writeVarint(transform_data, trans_id)
    end
    peek_buffer(transform_data, "transform_data")

    # 2. Info meta
    info_data = PipeBuffer()
    flush_info_headers!(info_data, t.write_persistent_headers, InfoType.PERSISTENT)
    flush_info_headers!(info_data, t.write_headers, InfoType.NORMAL)
    peek_buffer(info_data, "info_data")

    # 3. Header meta
    header_data = PipeBuffer()
    num_transforms = length(t.write_transforms)
    writeVarint(header_data, t.proto_id)
    writeVarint(header_data, num_transforms)
    peek_buffer(header_data, "header_data")

    # Calculate sizes
    header_size = bytesavailable(transform_data) + bytesavailable(info_data) +
        bytesavailable(header_data)
    padding_size = 4 - (header_size % 4)
    header_size += padding_size

    # Write header meta data
    wsz += header_size + 10 # MAGIC(2) | FLAGS(2) + SEQ_ID(4) + HEADER_SIZE(2)
    header_words = header_size ÷ 4
    @debug "make_header_message"  header_size padding_size header_words

    if wsz > Magic.MAX_FRAME_SIZE
        write(buf, hton(Magic.BIG_FRAME_MAGIC))
        write(buf, hton(UInt64(wsz)))
    else
        write(buf, hton(UInt32(wsz)))
    end
    write(buf, hton(UInt16(Magic.HEADER_MAGIC >> 16)))
    write(buf, hton(UInt16(t.flags)))
    write(buf, hton(UInt32(t.seqid)))
    write(buf, hton(UInt16(header_words)))

    # Write all data now
    write(buf, take!(header_data))
    write(buf, take!(transform_data))
    write(buf, take!(info_data))
    write(buf, zeros(UInt8, padding_size))
    write(buf, wout)

    return buf
end

function flush_info_headers!(buf::IOBuffer, headers::AbstractDict{<:String,<:String}, type::Integer)
    if length(headers) > 0
        writeVarint(buf, type)
        writeVarint(buf, length(headers))
        foreach(headers) do (key, val)
            writeVarint(buf, length(key))
            write(buf, codeunits(key))
            writeVarint(buf, length(val))
            write(buf, codeunits(val))
        end
        empty!(headers)
    end
end

# debug purpose only
function peek_buffer(buf::IOBuffer, label::AbstractString)
    n = bytesavailable(buf)
    @debug "$label($n bytes)" tohex(buf.data[1:n])
end

# Borrowed from protocol.jl
writeVarint(io::IO, i::T) where {T <: Integer} = _write_uleb(io, i)
readVarint(io::IO, t::Type{T}=Int64) where {T <: Integer} = _read_uleb(io, t)
