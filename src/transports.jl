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
read(t::TSASLClientTransport, type::Type{<:Unsigned}) = read(t.tp, type)
read(t::TSASLClientTransport, sz::Integer) = read(t.tp, sz)
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
function read(t::TFramedTransport, type::Type{<:Unsigned})
    navlb = bytesavailable(t.rbuff)
    if navlb == 0
        readframe(t)
    end
    return read(t.rbuff, type)
end
function read(t::TFramedTransport, sz::Integer)
    navlb = bytesavailable(t.rbuff)
    if navlb == 0
        readframe(t)
    end
    return read(t.rbuff, sz)
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

function close(tsock::TSocketBase)
    if isopen(tsock.io)
        close(tsock.io)
        @debug("Closed socket", tsock)
    else
        @debug("Socket cannot be closed", tsock)
    end
    return nothing
end

rawio(tsock::TSocketBase) = tsock.io

function read!(tsock::TSocketBase, buff::Vector{UInt8})
    result = read!(tsock.io, buff)
    @debug("TSocketBase.read!", tsock, tohex(buff))
    return result
end

function read(tsock::TSocketBase, sz::Integer)
    result = read(tsock.io, sz)
    # The `read` function does not throw when the socket is already closed.
    # Instead, it just returns an empty array. Need to throw so that the
    # server can exit out of loop when this happens.
    length(result) !== sz && throw(EOFError())
    @debug("TSocketBase.read", tsock, sz, tohex(result))
    return result
end

function read(tsock::TSocketBase, type::Type{<:Unsigned})
    result = read(tsock.io, type)
    @debug("TSocketBase.read", tsock, type, tohex(result))
    return result
end


function write(tsock::TSocketBase, buff::Vector{UInt8})
    @debug("TSocketBase.write", tsock, tohex(buff))
    return write(tsock.io, buff)
end

function write(tsock::TSocketBase, b::UInt8)
    @debug("TSocketBase.write", tsock, b)
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
read(t::TMemoryTransport, type::Type{<:Unsigned}) = read(t.buff, type)
read(t::TMemoryTransport, sz::Integer) = read(t.buff, sz)
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
read(t::TFileTransport, type::Type{<:Unsigned}) = read(t.handle, type)
read(t::TFileTransport, sz::Integer) = read(t.handle, sz)
write(t::TFileTransport, buff::Vector{UInt8}) = write(t.handle, buff)
write(t::TFileTransport, b::UInt8) = write(t.handle, b)

# ---------------------------------------------------------------------
# THeader transport
#
# The following code is largely adapted from the Python implementation
# of the THeader transport, with the exception that it does not include
# any code that handles deprecated/unframed protocol.
# ---------------------------------------------------------------------

# Define constants

module ProtocolType
    @enum ProtocolTypeEnum begin
        BINARY = 0
        COMPACT = 2
        UNKNOWN = 100
    end
end
using .ProtocolType: ProtocolTypeEnum

module ClientType
    @enum ClientTypeEnum begin
        HEADER = 0
        FRAMED_DEPRECATED = 1
        UNFRAMED_DEPRECATED = 2
        HTTP_SERVER = 3
        HTTP_CLIENT = 4
        FRAMED_COMPACT = 5
        HTTP_GET = 7
        UNKNOWN = 8
        UNFRAMED_COMPACT_DEPRECATED = 9
    end
end
using .ClientType: ClientTypeEnum

module TransformID
    @enum TransformIDEnum begin
        NONE = 0
        ZLIB = 1
        HMAC = 2
        SNAPPY = 3
        QLZ = 4
        ZSTD = 5
    end
end
using .TransformID: TransformIDEnum

module InfoID
    @enum InfoIDEnum begin
        NORMAL = 1
        PERSISTENT = 2
    end
end
using .InfoID: InfoIDEnum

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

module HeaderConstants
    const CLIENT_METADATA_KEY = "client_metadata"
    const CLIENT_METADATA_VALUE = """{"agent":"Julia THeaderTransport"}"""
end

const HeadersType = Dict{String,String}

"""
    THeaderTransport{T <: TTransport} <: TTransport

THeaderTransport is a transport itself but it also wraps another transport.
For examples, `THeaderTransport{TSocket}` or `THeaderTransport{TMemory}`.
"""
mutable struct THeaderTransport{T <: TTransport} <: TTransport
    tp::T
    rbuf::IOBuffer
    wbuf::IOBuffer
    seqid::Int
    flags::Int
    header_words::Int
    frame_size::Int
    read_transforms::Vector{TransformIDEnum}
    write_transforms::Vector{TransformIDEnum}
    proto_id::ProtocolTypeEnum
    num_transforms::Int
    client_type::ClientTypeEnum
    read_headers::HeadersType
    read_persistent_headers::HeadersType
    write_headers::HeadersType
    write_persistent_headers::HeadersType
    max_frame_size::UInt64

    THeaderTransport(transport::T) where {T <: TTransport} = new{T}(
        transport,
        PipeBuffer(),          # rbuf
        PipeBuffer(),          # wbuf
        0,                     # seqid
        0,                     # flags
        0,                     # header_words
        0,                     # frame_size
        TransformIDEnum[],     # read_transforms
        TransformIDEnum[],     # write_transforms
        ProtocolType.UNKNOWN,  # proto_id
        0,                     # number of headers
        ClientType.HEADER,     # client_type
        HeadersType(),         # read_headers
        HeadersType(),         # read_persistent_headers
        HeadersType(),         # write_headers
        HeadersType(),         # write_persistent_headers
        Magic.MAX_FRAME_SIZE,  # max_frame_size
    )
end

"""
    HeaderMeta

Keep track of some metadata information about the header message.
"""
struct HeaderMeta
    header_size::Int    # number of bytes in the header including padding
    padding_size::Int   # padding to 32-bit boundary
    header_words::Int   # number of words (32-bit values) including padding
    message_size::Int   # message size (excluding the top LENGTH word)
end

rawio(t::THeaderTransport)  = rawio(t.tp)
open(t::THeaderTransport)   = open(t.tp)
close(t::THeaderTransport)  = close(t.tp)
isopen(t::THeaderTransport) = isopen(t.tp)

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

"""
    read_frame!(t::THeaderTransport)

Read a single frame. Many fields in the transport object
will be upated with data read from the network.
"""
function read_frame!(t::THeaderTransport)
    word1 = read(t.tp, 4)
    sz = extract(word1, Int32)

    # For safety reason, check the first byte and see if it happens to be
    # the legacy binary/compact protocol.
    proto_id = word1[1]
    @debug("read_frame!", tohex(word1), sz, proto_id)

    proto_id in (BINARY_PROTOCOL_ID, COMPACT_PROTOCOL_ID) &&
        throw_header_exception("Unframed protocols are deprecated already")
    sz == Magic.HTTP_SERVER_MAGIC &&
        throw_header_exception("HTTP server not supported")

    if sz == Magic.BIG_FRAME_MAGIC
        sz = extract(read(t.tp, 8), UInt64)
    end
    t.frame_size = sz

    magic = read(t.tp, 2)
    proto_id = magic[1]
    proto_id in (BINARY_PROTOCOL_ID, COMPACT_PROTOCOL_ID) &&
        throw_header_exception("Header protocol expected rather than binary/compact")

    if magic == Magic.PACKED_HEADER_MAGIC
        @debug("Found header magic", tohex(magic))
        check_frame_size(t.frame_size, t.max_frame_size)
        buf = read_frame_into_buffer!(t)
        read_header_format!(t, buf)
    else
        t.client_type = ClientType.UNKNOWN
        throw_header_exception("Client type $(t.client_type) not supported on server")
    end
    return nothing
end

"""
    read_frame_into_buffer!(t::THeaderTransport)

Read data from the network into a buffer. Update the transport object
with header meta data information.
"""
function read_frame_into_buffer!(t::THeaderTransport)
    t.client_type = ClientType.HEADER
    # flags(2), seq_id(4), header_words(2)
    n_header_meta = read(t.tp, 8)
    t.flags = extract(n_header_meta, UInt16, 1)
    t.seqid = extract(n_header_meta, UInt32, 3)
    t.header_words = extract(n_header_meta, UInt16, 7)
    remaining = t.frame_size - 10
    @debug("read_frame_into_buffer!", proto_id, tohex(n_header_meta),
        tohex(t.flags), tohex(t.seqid), t.header_words, remaining)

    buf = IOBuffer()
    write(buf, Magic.PACKED_HEADER_MAGIC) # 2 bytes
    write(buf, n_header_meta) # 8 bytes
    write(buf, read(t.tp, remaining))  # rest of header message
    debug_buffer("read_frame_into_buffer!", buf)

    return buf
end

function throw_header_exception(message::AbstractString)
    throw(TTransportException(TransportExceptionTypes.UNKNOWN, message))
end

function check_frame_size(sz, max_size)
    if sz > max_size
        throw_header_exception("Frame size too large: $sz (max is $max_size)")
    end
    return nothing
end

"""
    read_header_format!(t::THeaderTransport, buf::IOBuffer)

Given data in `buf`, read head meta data, headers, and payload.

The following fields in `THeaderTransport` should be updated:
- proto_id
- read_transforms
- read_headers
- read_persisitent_headers
- rbuf (payload)
"""
function read_header_format!(t::THeaderTransport, buf::IOBuffer)
    # start right after magic(2), flags(2), seq_id(4), header_words(2)
    header_meta_size = 10

    # find out where the payload begins
    header_size = t.header_words * 4
    header_size <= t.frame_size ||
        throw_header_exception("Header size $(header_size) is larger than frame size $sz")

    # read header meta
    seek(buf, header_meta_size)
    t.proto_id = readVarint(buf, ProtocolTypeEnum)
    t.num_transforms = readVarint(buf)

    end_header = header_meta_size + header_size
    @debug("read_header_format!", t.proto_id, t.num_transforms, end_header)

    read_transform_ids!(t, buf)
    read_all_info_headers!(t, buf, end_header)
    read_payload!(t, buf, end_header)
    return nothing
end

"""
    read_transform_ids!(t::THeaderTransport, buf::IOBuffer)

Read all tranform id's. Note that the transform id's are placed in the
transport's `read_tarnsform` field in the reverse order (last one first).
That's because read transforms need to happen in the reverse order of
write transforms.
"""
function read_transform_ids!(t::THeaderTransport, buf::IOBuffer)
    # clear out previous transformations
    t.read_transforms = TransformIDEnum[]
    for _ in 1:t.num_transforms
        trans_id = readVarint(buf, TransformIDEnum)
        if trans_id in (TransformID.ZLIB, TransformID.ZSTD) # TODO: Add Snappy support
            insert!(t.read_transforms, 1, trans_id)
        else
            throw_header_exception("Unsupport transformation: $trans_id")
        end
    end
    return nothing
end

"""
    read_all_info_headers!(t::THeaderTransport, buf::IOBuffer, end_header::Integer)

Read all info headers from `buf`.
"""
function read_all_info_headers!(t::THeaderTransport, buf::IOBuffer, end_header::Integer)
    empty!(t.read_headers)

    # The number of header groups is unknown, and so it keeps reading until
    # it hits the end_header marker.
    while position(buf) < end_header
        info_id_val = readVarint(buf)
        if info_id_val != 0  # ignore paddings
            info_id = InfoIDEnum(info_id_val)
            read_info_headers!(t, info_id, buf, end_header)
        end
    end
    merge!(t.read_headers, t.read_persistent_headers)
    return nothing
end

"""
    read_payload!(t::THeaderTransport, buf::IOBuffer, end_header::Integer)

Read payload from `buf`. Untransform the payload and place the data in the
transport's read buffer `rbuf`.
"""
function read_payload!(t::THeaderTransport, buf::IOBuffer, end_header::Integer)
    seek(buf, end_header)
    @debug("read_header_format! seeking to end_header", end_header)
    payload_size = t.frame_size - end_header
    payload = read(buf, payload_size)
    @debug("read_header_format!", tohex(payload))
    t.rbuf = PipeBuffer(untransform(t, payload))
    return nothing
end

"""
    read_info_headers!(t::THeaderTransport, info_id::Int, buf::IOBuffer, limit::Integer)

Read info headers from `buf`. The `info_id` is used to indicate whether
the data should be read into `read_headers` or `read_persisitent_headers`.
Throws exception if buffer position ever past the provided `limit`.
"""
function read_info_headers!(t::THeaderTransport, info_id::InfoIDEnum, buf::IOBuffer, limit::Integer)
    dct = if info_id === InfoID.NORMAL
        t.read_headers
    elseif info_id === InfoID.PERSISTENT
        t.read_persisitent_headers
    else
        throw_header_exception("Bug: enum not handled: $info_id")
    end

    num_keys = readVarint(buf)
    for _ in 1:num_keys
        key = read_string(buf, limit)
        val = read_string(buf, limit)
        dct[key] = val
    end
    return nothing
end

"""
    read_string(buf::IOBuffer, limit::Integer)

Read a string from `buf`. All strings starts with a length stored as varint,
followed by the characters of the string. Throws exception if the buffer
position is past the provided limit.
"""
function read_string(buf::IOBuffer, limit::Integer)
    str_sz = readVarint(buf)
    position(buf) + str_sz > limit &&
        throw_header_exception("String read too big: $str_sz, limit=$end_header")
    return String(read(buf, str_sz))
end

write(t::THeaderTransport, buff::Vector{UInt8}) = write(t.wbuf, buff)
write(t::THeaderTransport, b::UInt8) = write(t.wbuf, b)

"""
    transform(t::THeaderTransport, data::Vector{UInt8})

Transform `data` using the configured `write_transforms` from the transport.
"""
function transform(t::THeaderTransport, data::Vector{UInt8})
    if !isempty(t.write_transforms)
        @debug("Transform method(s): " * join(t.write_transforms, ","))
    end
    for trans_id in t.write_transforms
        if trans_id == TransformID.ZLIB
            data = transform_data(ZlibCompressor, data)
        elseif trans_id == TransformID.ZSTD
            data = transform_data(ZstdCompressor, data)
        else
            throw_header_exception("Unsupported transformation: $trans_id")
        end
    end
    return data
end

"""
    untransform(t::THeaderTransport, data::Vector{UInt8})

Untransform `data` using the configured `read_transforms` from the transport.
"""
function untransform(t::THeaderTransport, data::Vector{UInt8})
    if !isempty(t.read_transforms)
        @debug("Unransform method(s): " * join(t.read_transforms, ","))
    end
    for trans_id in t.read_transforms
        if trans_id == TransformID.ZLIB
            data = transform_data(ZlibDecompressor, data)
        elseif trans_id == TransformID.ZSTD
            data = transform_data(ZstdDecompressor, data)
        else
            throw_header_exception("Unsupported transformation: $trans_id")
        end
    end
    return data
end

"""
    flush(t::THeaderTransport)

Make a new header message and flush it over the wire.
"""
function flush(t::THeaderTransport)
    # Flush write buffer (wbuf) which contains the payload
    payload = transform(t, take!(t.wbuf))
    payload_size = length(payload)

    # Create a new IO buffer to hold the entire message including header
    buf = make_header_message(t, payload)

    message_length_offset = payload_size < Magic.MAX_FRAME_SIZE ? 4 : 12
    frame_size = bytesavailable(buf) - message_length_offset
    check_frame_size(frame_size, t.max_frame_size)

    debug_buffer("Header Message", buf)
    write(t.tp, take!(buf))
    flush(t.tp)
end

"""
    init_write_headers!(t::THeaderTransport)

Initialize the transport's `write_headers` with standard metadata.
"""
function init_write_headers!(t::THeaderTransport)
    t.write_headers[HeaderConstants.CLIENT_METADATA_KEY] = HeaderConstants.CLIENT_METADATA_VALUE
    return nothing
end

"""
    make_header_transform_data(t::THeaderTransport)

Return a buffer with transform id's for sending a header message.
"""
function make_header_transform_data(t::THeaderTransport)
    buf = PipeBuffer()
    for trans_id in t.write_transforms
        writeVarint(buf, trans_id)
    end
    debug_buffer("transform_data", buf)
    return buf
end

"""
    make_header_info_data(t::THeaderTransport)

Return a buffer with info headers for sending a header message.
"""
function make_header_info_data(t::THeaderTransport)
    buf = PipeBuffer()
    flush_info_headers!(buf, t.write_persistent_headers, InfoID.PERSISTENT)
    flush_info_headers!(buf, t.write_headers, InfoID.NORMAL)
    debug_buffer("info_data", buf)
    return buf
end

"""
    make_header_meta_data(t::THeaderTransport)

Return a buffer with header meta data (just `proto_id` and `num_transforms`).
"""
function make_header_meta_data(t::THeaderTransport)
    buf = PipeBuffer()
    num_transforms = length(t.write_transforms)
    writeVarint(buf, t.proto_id)
    writeVarint(buf, num_transforms)
    debug_buffer("header_data", buf)
    return buf
end

"""
    calc_header_meta(transform_data::IOBuffer,
        info_data::IOBuffer,
        header_data::IOBuffer,
        payload::Vector{UInt8},
    )

Calculate some basic sizes for the header meta data.
"""
function calc_header_meta(
    transform_data::IOBuffer,
    info_data::IOBuffer,
    header_data::IOBuffer,
    payload::Vector{UInt8},
)
    header_size = bytesavailable(transform_data) + bytesavailable(info_data) +
        bytesavailable(header_data)
    padding_size = 4 - (header_size % 4)
    header_size += padding_size
    header_words = header_size ÷ 4
    # MAGIC(2) + FLAGS(2) + SEQ_ID(4) + HEADER_SIZE(2) = 10 bytes
    message_size = length(payload) + header_size + 10
    return HeaderMeta(header_size, padding_size, header_words, message_size)
end

"""
    make_header_top_part(t::THeaderTransport, header_meta::HeaderMeta)

Return a buffer with the top part of header message - up to the
header_size/32 field, but not including any header data.
"""
function make_header_top_part(t::THeaderTransport, header_meta::HeaderMeta)
    buf = PipeBuffer()
    if header_meta.message_size > Magic.MAX_FRAME_SIZE
        write(buf, hton(Magic.BIG_FRAME_MAGIC))
        write(buf, hton(UInt64(header_meta.message_size)))
    else
        write(buf, hton(UInt32(header_meta.message_size)))
    end
    write(buf, hton(UInt16(Magic.HEADER_MAGIC >> 16)))
    write(buf, hton(UInt16(t.flags)))
    write(buf, hton(UInt32(t.seqid)))
    write(buf, hton(UInt16(header_meta.header_words)))
    return buf
end

"""
    make_header_message(t::THeaderTransport, payload::Vector{UInt8})

Return a buffer with header message populated.
"""
function make_header_message(t::THeaderTransport, payload::Vector{UInt8})
    init_write_headers!(t)

    transform_data = make_header_transform_data(t)
    info_data = make_header_info_data(t)
    header_data = make_header_meta_data(t)

    header_meta = calc_header_meta(transform_data, info_data, header_data, payload)
    top_part = make_header_top_part(t, header_meta)

    buf = PipeBuffer()
    write(buf, take!(top_part))
    write(buf, take!(header_data))
    write(buf, take!(transform_data))
    write(buf, take!(info_data))
    write(buf, zeros(UInt8, header_meta.padding_size))
    write(buf, payload)

    return buf
end

"""
    flush_info_headers!(buf::IOBuffer, headers::HeadersType, info_id::InfoIDEnum)

Flush info headers to the buffer. The `headers` dictionary will be emptied
after this call.
"""
function flush_info_headers!(buf::IOBuffer, headers::HeadersType, info_id::InfoIDEnum)
    if length(headers) > 0
        writeVarint(buf, info_id)
        writeVarint(buf, length(headers))
        foreach(headers) do (key, val)
            writeVarint(buf, length(key))
            write(buf, codeunits(key))
            writeVarint(buf, length(val))
            write(buf, codeunits(val))
        end
        empty!(headers)
    end
    return nothing
end
