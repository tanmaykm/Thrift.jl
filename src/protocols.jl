
struct _enum_TProtocolExceptionTypes
    UNKNOWN::Int32
    INVALID_DATA::Int32
    NEGATIVE_SIZE::Int32
    SIZE_LIMIT::Int32
    BAD_VERSION::Int32
end

const ProtocolExceptionType = _enum_TProtocolExceptionTypes(Int32(0), Int32(1), Int32(2), Int32(3), Int32(4))

struct TProtocolException
    typ::Int32
    message::TUTF8

    TProtocolException(typ::Int32=ProtocolExceptionType.UNKNOWN, message::AbstractString="") = new(typ, message)
end


# ==========================================
# Binary Protocol
# ==========================================
const BINARY_VERSION_MASK = 0xffff0000
const BINARY_VERSION_1 = 0x80010000
const BINARY_TYPE_MASK = 0x000000ff
const BINARY_PROTOCOL_ID = 0x80

mutable struct TBinaryProtocol <: TProtocol
    t::TTransport
    strict_read::Bool
    strict_write::Bool

    TBinaryProtocol(t::TTransport, strict_read::Bool=true, strict_write::Bool=true) = new(t, strict_read, strict_write)
end


function writeMessageBegin(p::TBinaryProtocol, name::AbstractString, mtype::Int32, seqid::Integer)
    nbyt = 0
    @debug("writeMessageBegin",name, mtype, seqid)
    if p.strict_write
        nbyt += write(p, BINARY_VERSION_1 | UInt32(mtype))
        @debug("wrote protocol version header", nbyt)
        nbyt += writeString(p, name)
        nbyt += writeI32(p, seqid)
    else
        nbyt += writeString(p, name)
        nbyt += writeByte(p, mtype)
        nbyt += writeI32(p, seqid)
    end
    nbyt
end

function writeFieldBegin(p::TBinaryProtocol, name::AbstractString, ttype::Int32, fid::Integer)
    @debug("writeFieldBegin", name, ttype, fid)
    nbyt = writeByte(p, ttype)
    nbyt += writeI16(p, fid)
    nbyt
end

writeFieldStop(p::TBinaryProtocol) = writeByte(p, TType.STOP)

function writeMapBegin(p::TBinaryProtocol, ktype::Int32, vtype::Int32, size::Integer)
    @debug("writeMapBegin", ktype, vtype, size)
    nbyt = writeByte(p, ktype)
    nbyt += writeByte(p, vtype)
    nbyt += writeI32(p, size)
    nbyt
end

function writeCollectionsBegin(p::TBinaryProtocol, etype::Int32, size::Integer)
    @debug("writeCollectionsBegin", etype, size)
    nbyt = writeByte(p, etype)
    nbyt += writeI32(p, size)
    nbyt
end

writeListBegin(p::TBinaryProtocol, etype::Int32, size::Integer) = writeCollectionsBegin(p, etype, size)
writeSetBegin(p::TBinaryProtocol, etype::Int32, size::Integer) = writeCollectionsBegin(p, etype, size)

write(p::TBinaryProtocol, b::Bool)              = write(p, b ? 0x01 : 0x00)
write(p::TBinaryProtocol, i::TBYTE)             = _write_fixed(p.t, i, true)

write(p::TBinaryProtocol, i::TI16)              = write(p, reinterpret(UInt16,i))
write(p::TBinaryProtocol, i::UInt16)            = _write_fixed(p.t, i, true)

write(p::TBinaryProtocol, i::TI32)              = write(p, reinterpret(UInt32,i))
write(p::TBinaryProtocol, i::UInt32)            = _write_fixed(p.t, i, true)

write(p::TBinaryProtocol, i::TI64)              = write(p, reinterpret(UInt64,i))
write(p::TBinaryProtocol, i::UInt64)            = _write_fixed(p.t, i, true)

write(p::TBinaryProtocol, d::TDOUBLE)           = _write_fixed(p.t, reinterpret(UInt64,d), true)
write(p::TBinaryProtocol, s::TUTF8)             = write(p, convert(Vector{UInt8}, codeunits(s)), true)
function write(p::TBinaryProtocol, a::Vector{UInt8}, framed::Bool=false)
    if framed
        nbyt = writeI32(p, length(a))
        nbyt += write(p, a)
        nbyt
    else
        write(p.t, a)
    end
end

function readMessageBegin(p::TBinaryProtocol)
    @debug("readMessageBegin")
    sz = read(p, UInt32)
    if sz > BINARY_VERSION_1
        version = sz & BINARY_VERSION_MASK
        (version != BINARY_VERSION_1) && throw(TProtocolException(ProtocolExceptionType.BAD_VERSION, "Bad binary protocol version: $version"))
        typ = Int32(sz & BINARY_TYPE_MASK)
        name = readString(p)
        seqid = readI32(p)
    else
        p.strict_read && throw(TProtocolException(ProtocolExceptionType.BAD_VERSION, "No protocol version header"))
        name =  String(read!(p, Array{UInt8}(undef, Int(sz))))
        typ = Int32(readByte(p))
        seqid = readI32(p)
    end
    @debug("readMessageBegin read", name, typ, seqid, sz)
    (name, typ, seqid)
end

function readFieldBegin(p::TBinaryProtocol)
    @debug("readFieldBegin")
    typ = readByte(p)
    fid = (typ == TType.STOP) ? Int16(0) : readI16(p)
    @debug("readFieldBegin", typ, fid)
    (nothing, typ, fid)
end
readFieldStop(p::TBinaryProtocol) = readByte(p)
readMapBegin(p::TBinaryProtocol) = (readByte(p), readByte(p), readI32(p))
readListBegin(p::TBinaryProtocol) = (readByte(p), readI32(p))
readSetBegin(p::TBinaryProtocol) = (readByte(p), readI32(p))

read(p::TBinaryProtocol, ::Type{Bool})          = (0x0 != readByte(p))
read(p::TBinaryProtocol, ::Type{TBYTE})         = _read_fixed(p.t, UInt8(0), 1, true)

read(p::TBinaryProtocol, ::Type{TI16})          = reinterpret(TI16, read(p, UInt16))
read(p::TBinaryProtocol, ::Type{UInt16})        = _read_fixed(p.t, UInt16(0), 2, true)

read(p::TBinaryProtocol, ::Type{TI32})          = reinterpret(TI32, read(p, UInt32))
read(p::TBinaryProtocol, ::Type{UInt32})        = _read_fixed(p.t, UInt32(0), 4, true)

read(p::TBinaryProtocol, ::Type{TI64})          = reinterpret(TI64, read(p, UInt64))
read(p::TBinaryProtocol, ::Type{UInt64})        = _read_fixed(p.t, UInt64(0), 8, true)

read(p::TBinaryProtocol, ::Type{TDOUBLE})       = reinterpret(TDOUBLE, _read_fixed(p.t, UInt64(0), 8, true))
read!(p::TBinaryProtocol, a::Vector{UInt8})     = read!(p.t, a)
read(p::TBinaryProtocol, ::Type{TUTF8})         = convert(TUTF8, String(read(p, Vector{UInt8})))
read(p::TBinaryProtocol, ::Type{Vector{UInt8}}) = read!(p, Vector{UInt8}(undef, _read_fixed(p.t, UInt32(0), 4, true)))

# ==========================================
# Compact Protocol
# ==========================================
struct _enum_CType
    STOP::UInt8
    TRUE::UInt8
    FALSE::UInt8
    BYTE::UInt8
    I16::UInt8
    I32::UInt8
    I64::UInt8
    DOUBLE::UInt8
    BINARY::UInt8
    LIST::UInt8
    SET::UInt8
    MAP::UInt8
    STRUCT::UInt8
end
const CType = _enum_CType(0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C)

const CTYPE_TO_TTYPE = (TType.STOP, TType.BOOL, TType.BOOL, TType.BYTE, TType.I16, TType.I32, TType.I64, TType.DOUBLE, TType.STRING, TType.LIST, TType.SET, TType.MAP, TType.STRUCT)
const TTYPE_TO_CTYPE = (CType.STOP, 0xff, CType.TRUE, CType.BYTE, CType.DOUBLE, Nothing, CType.I16, Nothing, CType.I32, Nothing, CType.I64, CType.BINARY, CType.STRUCT, CType.MAP, CType.SET, CType.LIST)

const COMPACT_PROTOCOL_ID       = 0x82
const COMPACT_VERSION           = 1
const COMPACT_VERSION_MASK      = 0x1f
const COMPACT_TYPE_MASK         = 0xe0
const COMPACT_TYPE_SHIFT_AMOUNT = 5

struct _enum_CState
    CLEAR::Int32
    FIELD_WRITE::Int32
    VALUE_WRITE::Int32
    CONTAINER_WRITE::Int32
    BOOL_WRITE::Int32
    FIELD_READ::Int32
    CONTAINER_READ::Int32
    VALUE_READ::Int32
    BOOL_READ::Int32
end
const CState = _enum_CState(Int32(0), Int32(1), Int32(2), Int32(3), Int32(4), Int32(5), Int32(6), Int32(7), Int32(8))

const CSTATES_WRITE_STRUCT_BEGIN        = (CState.CLEAR, CState.CONTAINER_WRITE, CState.VALUE_WRITE)
const CSTATES_WRITE_FIELD_END           = (CState.VALUE_WRITE, CState.BOOL_WRITE)
const CSTATES_WRITE_COLLECTION_BEGIN    = (CState.VALUE_WRITE, CState.CONTAINER_WRITE)
const CSTATES_READ_STRUCT_BEGIN         = (CState.CLEAR, CState.CONTAINER_READ, CState.VALUE_READ)
const CSTATES_READ_FIELD_END            = (CState.VALUE_READ, CState.BOOL_READ)
const CSTATES_READ_COLLECTION_BEGIN     = (CState.CONTAINER_READ, CState.VALUE_READ)
const CSTATES_READ_BOOL                 = (CState.CONTAINER_READ, CState.BOOL_READ)


mutable struct TCompactProtocol <: TProtocol
    t::TTransport
    state::Int32
    last_fid::Int16
    bool_fid::Int16
    bool_value::UInt8
    structs::Vector{Tuple}
    containers::Vector{Int32}

    TCompactProtocol(t::TTransport) = new(t, CState.CLEAR, 0, 0, 0, Tuple[], Int32[])
end

writeVarint(p::TCompactProtocol, i::T) where {T <: Integer} = _write_uleb(p.t, i)
readVarint(p::TCompactProtocol, t::Type{T}) where {T <: Integer} = _read_uleb(p.t, t)

#chkstate(p, s) = !(p.state in s) && (@debug("chkstate: $(p.state) vs. $s"); error("Internal error. Incorrect state."))
chkstate(p, s) = !(p.state in s) && error("Internal error. Incorrect state $(p.state). Expected: $s")
byte2ctype(byte) = (byte & 0x0f)
byte2ttype(byte) = CTYPE_TO_TTYPE[byte2ctype(byte) + 0x01]

function writeMessageBegin(p::TCompactProtocol, name::AbstractString, mtype::Int32, seqid::Integer)
    @debug("writeMessageBegin", name, mtype, seqid)
    chkstate(p, CState.CLEAR)
    nbyt = writeByte(p, COMPACT_PROTOCOL_ID)
    nbyt += writeByte(p, COMPACT_VERSION | (mtype << COMPACT_TYPE_SHIFT_AMOUNT))
    nbyt += writeVarint(p, seqid)
    nbyt += writeString(p, name)
    p.state = CState.VALUE_WRITE
    nbyt
end

function writeMessageEnd(p::TCompactProtocol)
    @debug("writeMessageEnd")
    chkstate(p, CState.VALUE_WRITE)
    p.state = CState.CLEAR
    0
end

function writeStructBegin(p::TCompactProtocol, name::AbstractString)
    @debug("writeStructBegin", name)
    chkstate(p, CSTATES_WRITE_STRUCT_BEGIN)
    push!(p.structs, (p.state, p.last_fid))
    p.state = CState.FIELD_WRITE
    p.last_fid = Int16(0)
    0
end

function writeStructEnd(p::TCompactProtocol)
    @debug("writeStructEnd")
    chkstate(p, CState.FIELD_WRITE)
    (p.state, p.last_fid) = pop!(p.structs)
    0
end

writeFieldStop(p::TCompactProtocol) = writeByte(p, 0x00)

function writeFieldHeader(p::TCompactProtocol, mtype::UInt8, fid::Int16)
    @debug("writeFieldHeader", mtype, fid, last_fid=p.last_fid)
    nbyt = 0
    delta = fid - p.last_fid
    if 0 < delta <= 15
      nbyt += writeByte(p, (UInt8(delta) << 4) | mtype)
    else
      nbyt += writeByte(p, mtype)
      nbyt += writeI16(p, fid)
    end
    p.last_fid = fid
    nbyt
end

function writeFieldBegin(p::TCompactProtocol, name::AbstractString, ttype::Int32, fid::Integer)
    @debug("writeFieldBegin", name, ttype, fid)
    nbyt = 0
    chkstate(p, CState.FIELD_WRITE)
    if ttype == TType.BOOL
      p.state = CState.BOOL_WRITE
      p.bool_fid = fid
    else
      p.state = CState.VALUE_WRITE
      nbyt += writeFieldHeader(p, TTYPE_TO_CTYPE[ttype+1], Int16(fid))
    end
    nbyt
end

function writeFieldEnd(p::TCompactProtocol)
    @debug("writeFieldEnd")
    chkstate(p, CSTATES_WRITE_FIELD_END)
    p.state = CState.FIELD_WRITE
    0
end

function writeCollectionsBegin(p::TCompactProtocol, etype::Int32, sz::Int32)
    @debug("writeCollectionsBegin", etype, sz)
    nbyt = 0
    chkstate(p, CSTATES_WRITE_COLLECTION_BEGIN)
    if sz <= 14
        nbyt += writeByte(p, (UInt8(sz) << 4) | TTYPE_TO_CTYPE[etype+1])
    else
        nbyt += writeByte(p, 0xf0 | TTYPE_TO_CTYPE[etype+1])
        nbyt += writeSize(p, sz)
    end
    push!(p.containers, p.state)
    p.state = CState.CONTAINER_WRITE
    nbyt
end
writeSetBegin(p::TCompactProtocol, etype::Int32, size::Integer) = writeCollectionsBegin(p, etype, Int32(size))
writeListBegin(p::TCompactProtocol, etype::Int32, size::Integer) = writeCollectionsBegin(p, etype, Int32(size))

function writeMapBegin(p::TCompactProtocol, ktype::Int32, vtype::Int32, size::Integer)
    @debug("writeMapBegin", ktype, vtype, size)
    nbyt = 0
    chkstate(p, CSTATES_WRITE_COLLECTION_BEGIN)
    if size == 0
        nbyt += writeByte(p, 0x00)
    else
        nbyt += writeSize(p, size)
        nbyt += writeByte(p, (TTYPE_TO_CTYPE[ktype+1] << 4) | TTYPE_TO_CTYPE[vtype+1])
    end
    push!(p.containers, p.state)
    p.state = CState.CONTAINER_WRITE
    nbyt
end

function writeCollectionEnd(p::TCompactProtocol)
    @debug("writeCollectionEnd")
    chkstate(p, CState.CONTAINER_WRITE)
    p.state = pop!(p.containers)
    0
end

writeMapEnd(p::TCompactProtocol)    = writeCollectionEnd(p)
writeListEnd(p::TCompactProtocol)   = writeCollectionEnd(p)
writeSetEnd(p::TCompactProtocol)    = writeCollectionEnd(p)

function writeBool(p::TCompactProtocol, b::Bool)
    if p.state == CState.BOOL_WRITE
        writeFieldHeader(p, b ? CType.TRUE : CType.FALSE, p.bool_fid)
    elseif p.state == CState.CONTAINER_WRITE
        writeByte(p, b ? CType.TRUE : CType.FALSE)
    else
        error("Invalid state in compact protocol")
    end
end

writeSize(p::TCompactProtocol, sz::Integer) = writeVarint(p, Int32(sz))

write(p::TCompactProtocol, i::TBYTE)            = _write_fixed(p.t, i, true)
write(p::TCompactProtocol, i::TI16)             = _write_zigzag(p.t, i)
write(p::TCompactProtocol, i::TI32)             = _write_zigzag(p.t, i)
write(p::TCompactProtocol, i::TI64)             = _write_zigzag(p.t, i)
write(p::TCompactProtocol, d::TDOUBLE)          = _write_fixed(p.t, reinterpret(UInt64,d), false)
write(p::TCompactProtocol, s::TUTF8)            = write(p, convert(Vector{UInt8}, codeunits(s)), true)
function write(p::TCompactProtocol, a::Vector{UInt8}, framed::Bool=false)
    if framed
        @debug("writing framed binary")
        nbyt = writeSize(p, length(a))
        nbyt += write(p, a)
        nbyt
    else
        @debug("writing unframed binary")
        write(p.t, a)
    end
end

function readMessageBegin(p::TCompactProtocol)
    @debug("readMessageBegin")
    chkstate(p, CState.CLEAR)
    proto_id = readByte(p)
    (proto_id != COMPACT_PROTOCOL_ID) && error("Incorrect protocol id: $proto_id")
    ver_type = readByte(p)
    typ = (ver_type & COMPACT_TYPE_MASK) >> COMPACT_TYPE_SHIFT_AMOUNT
    version = ver_type & COMPACT_VERSION_MASK
    (version != COMPACT_VERSION) && error("Incorrect version: $version. Need $COMPACT_VERSION")
    seqid = readVarint(p, Int32)
    name = readString(p)
    @debug("readMessageBegin", name, typ, seqid)
    (name, Int32(typ), seqid)
end

function readMessageEnd(p::TCompactProtocol)
    @debug("readMessageEnd")
    chkstate(p, CState.CLEAR)
    !isempty(p.structs) && error("Reading message went bad somewhere!")
    nothing
end

function readStructBegin(p::TCompactProtocol)
    @debug("readStructBegin")
    chkstate(p, CSTATES_READ_STRUCT_BEGIN)
    push!(p.structs, (p.state, p.last_fid))
    p.state = CState.FIELD_READ
    p.last_fid = 0
    nothing
end

function readStructEnd(p::TCompactProtocol)
    @debug("readStructEnd")
    chkstate(p, CState.FIELD_READ)
    (p.state, p.last_fid) = pop!(p.structs)
    nothing
end

function readFieldBegin(p::TCompactProtocol)
    @debug("readFieldBegin")
    chkstate(p, CState.FIELD_READ)
    typ = readByte(p)
    ((typ & 0x0f) == TType.STOP) && (return (nothing, Int32(0), Int16(0)))
    delta = (typ >> 4)
    fid = (delta == 0) ? readI16(p) : Int16(p.last_fid + delta)
    p.last_fid = fid
    typ = (typ & 0x0f)

    if typ == CType.TRUE
        p.state = CState.BOOL_READ
        p.bool_value = 0x01
    elseif typ == CType.FALSE
        p.state = CState.BOOL_READ
        p.bool_value = 0x00
    else
        p.state = CState.VALUE_READ
    end
    @debug("readFieldBegin", typ=byte2ttype(typ))
    (nothing, byte2ttype(typ), fid)
end

function readFieldEnd(p::TCompactProtocol)
    @debug("readFieldEnd")
    chkstate(p, CSTATES_READ_FIELD_END)
    p.state = CState.FIELD_READ
    nothing
end

function readCollectionBegin(p::TCompactProtocol)
    @debug("readCollectionBegin")
    chkstate(p, CSTATES_READ_COLLECTION_BEGIN)
    size_type = readByte(p)
    size = size_type >> 4
    typ = byte2ttype(size_type)
    (size == 0x0f) && (size = readSize(p))
    push!(p.containers, p.state)
    p.state = CState.CONTAINER_READ
    (typ, size)
end

readSetBegin(p::TCompactProtocol) = readCollectionBegin(p)
readListBegin(p::TCompactProtocol) = readCollectionBegin(p)

function readMapBegin(p::TCompactProtocol)
    @debug("readMapBegin")
    chkstate(p, CSTATES_READ_COLLECTION_BEGIN)
    size = readSize(p)
    @debug("map size", size)
    types = (size > 0) ? readByte(p) : 0
    @debug("map types", types)
    vtype = byte2ttype(types)
    @debug("map vtype", vtype)
    ktype = byte2ttype(types >> 4)
    @debug("map ktype", ktype)
    push!(p.containers, p.state)
    p.state = CState.CONTAINER_READ
    (ktype, vtype, size)
end

function readCollectionEnd(p::TCompactProtocol)
    @debug("readCollectionEnd")
    chkstate(p, CState.CONTAINER_READ)
    p.state = pop!(p.containers)
    nothing
end

readSetEnd(p::TCompactProtocol) = readCollectionEnd(p)
readListEnd(p::TCompactProtocol) = readCollectionEnd(p)
readMapEnd(p::TCompactProtocol) = readCollectionEnd(p)

function read(p::TCompactProtocol, ::Type{Bool})
    chkstate(p, CSTATES_READ_BOOL)
    (p.state == CState.BOOL_READ) && (return (p.bool_value == CType.TRUE))
    (p.state == CState.CONTAINER_READ) && (return (readByte(p) == CType.TRUE))
end

readSize(p::TCompactProtocol) = readVarint(p, Int32)

read(p::TCompactProtocol, t::Type{TBYTE})       = _read_fixed(p.t, UInt8(0), 1, true)
read(p::TCompactProtocol, t::Type{TI16})        = _read_zigzag(p.t, t)
read(p::TCompactProtocol, t::Type{TI32})        = _read_zigzag(p.t, t)
read(p::TCompactProtocol, t::Type{TI64})        = _read_zigzag(p.t, t)
read(p::TCompactProtocol, t::Type{TDOUBLE})     = reinterpret(TDOUBLE, _read_fixed(p.t, UInt64(0), 8, false))
read!(p::TCompactProtocol, a::Vector{UInt8})    = read!(p.t, a)
read(p::TCompactProtocol, ::Type{TUTF8})        = convert(TUTF8, String(read(p, Vector{UInt8})))
read(p::TCompactProtocol, ::Type{Vector{UInt8}}) = read!(p, Vector{UInt8}(undef, readSize(p)))

# ==========================================
# Header Protocol Begin
# ==========================================

mutable struct THeaderProtocol{T <: TTransport, P <: TProtocol} <: TProtocol
    t::T
    proto::P
end

function THeaderProtocol(p::TProtocol)
    # THeaderProtocol wraps an underlying protocol such as TBinaryProtocol
    protocol = THeaderProtocol(p.t, p)

    # Extract proto_id from the underlying protocol and update transport
    # This only works on the client side because THeaderTransport is a
    # client transport.
    if p.t isa THeaderTransport
        p.t.proto_id = proto_id(p)
    end

    return protocol
end

function writeMessageBegin(p::THeaderProtocol, name::AbstractString, mtype::Int32, seqid::Integer)
    writeMessageBegin(p.proto, name, mtype, seqid)
    if mtype in (MessageType.CALL, MessageType.ONEWAY)
        p.t.seqid = seqid
    end
end

writeMessageEnd(p::THeaderProtocol) = writeMessageEnd(p.proto)
writeFieldBegin(p::THeaderProtocol, name::AbstractString, ttype::Int32, fid::Integer) = writeFieldBegin(p.proto, name, ttype, fid)
writeFieldStop(p::THeaderProtocol) = writeFieldStop(p.proto)
writeMapBegin(p::THeaderProtocol, ktype::Int32, vtype::Int32, size::Integer) = writeMapBegin(p.proto, ktype, vtype, size)
writeCollectionsBegin(p::THeaderProtocol, etype::Int32, size::Integer) = writeCollectionsBegin(p.proto, etype, size)
writeListBegin(p::THeaderProtocol, etype::Int32, size::Integer) = writeListBegin(p.proto, etype, size)
writeSetBegin(p::THeaderProtocol, etype::Int32, size::Integer) = writeSetBegin(p.proto, etype, size)

function readMessageBegin(p::THeaderProtocol)
    reset_protocol(p)
    readMessageBegin(p.proto)
end

readFieldBegin(p::THeaderProtocol) = readFieldBegin(p.proto)
readFieldStop(p::THeaderProtocol) = readFieldStop(p.proto)
readMapBegin(p::THeaderProtocol) = readMapBegin(p.proto)
readListBegin(p::THeaderProtocol) = readListBegin(p.proto)
readSetBegin(p::THeaderProtocol) = readSetBegin(p.proto)

# TODO(tomkwong) Is this needed? What about other container types?
# read(p::THeaderProtocol, ::Type{T}) where {T<:TSTRUCT} = read(p.proto, T())

for _typ in _plain_types
    @eval begin
        write(p::THeaderProtocol, val::$(_typ)) = write(p.proto, val)
        read(p::THeaderProtocol, val::Type{$(_typ)}) = read(p.proto, val)
        skip(p::THeaderProtocol, val::Type{$(_typ)}) = skip(p.proto, val)
    end
end

# Allow protocol to be changed
function reset_protocol(p::THeaderProtocol)
    proto_id(p) === p.t.proto_id && return
    p.proto = make_protocol(p.t, p.t.proto_id)
end

function make_protocol(t::TTransport, proto_id::ProtocolTypeEnum)
    if proto_id == ProtocolType.BINARY
        return TBinaryProtocol(t)
    elseif proto_id == ProtocolType.COMPACT
        return TCompactProtocol(t)
    else
        throw(ArgumentError("Unknown proto_id: $proto_id"))
    end
end

# ==========================================
# Traits
# ==========================================

"""
    proto_id(p::TProtocol)

Return a value of `ProtocolTypeEnum` for the protocol.
"""
function proto_id end

proto_id(p::TBinaryProtocol) = ProtocolType.BINARY
proto_id(p::TCompactProtocol) = ProtocolType.COMPACT
proto_id(p::THeaderProtocol) = proto_id(p.proto)
proto_id(x::TProtocol) = throw(ArgumentError("Unsupported protocol type: $(typeof(x))"))
