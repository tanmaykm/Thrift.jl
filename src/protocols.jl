
type _enum_TProtocolExceptionTypes
    UNKNOWN::Int32
    INVALID_DATA::Int32
    NEGATIVE_SIZE::Int32
    SIZE_LIMIT::Int32
    BAD_VERSION::Int32
end

const ProtocolExceptionType = _enum_TProtocolExceptionTypes(int32(0), int32(1), int32(2), int32(3), int32(4))

type TProtocolException
    typ::Int32
    message::String

    TProtocolException(typ::Int32=ProtocolExceptionType.UNKNOWN, message::String="") = new(typ, message)
end


# ==========================================
# Binary Protocol Begin
# ==========================================
const BINARY_VERSION_MASK = 0xffff0000
const BINARY_VERSION_1 = 0x80010000
const BINARY_TYPE_MASK = 0x000000ff

type TBinaryProtocol <: TProtocol
    t::TTransport
    strict_read::Bool
    strict_write::Bool

    TBinaryProtocol(t::TTransport, strict_read::Bool=true, strict_write::Bool=true) = new(t, strict_read, strict_write)    
end


function writeMessageBegin(p::TBinaryProtocol, name::String, mtype::Int32, seqid::Integer)
    logmsg("writeMessageBegin name: $name, mtype: $mtype, seqid: $seqid")
    if p.strict_write
        writeI32(p, BINARY_VERSION_1 | mtype)
        writeString(p, name)
        writeI32(p, seqid)
    else
        writeString(p, name)
        writeByte(p, mtype)
        writeI32(p, seqid)
    end
end

function writeFieldBegin(p::TBinaryProtocol, name::String, ttype::Int32, fid::Integer)
    logmsg("writeFieldBegin name: $name, ttype: $ttype, fid: $fid")
    writeByte(p, ttype)
    writeI16(p, fid)
    nothing
end

writeFieldStop(p::TBinaryProtocol) = writeByte(p, TType.STOP)

function writeMapBegin(p::TBinaryProtocol, ktype::Int32, vtype::Int32, size::Integer)
    logmsg("writeMapBegin ktype: $ktype, vtype: $vtype, size: $size")
    writeByte(p, ktype)
    writeByte(p, vtype)
    writeI32(p, size)
    nothing
end

function writeListBegin(p::TBinaryProtocol, etype::Int32, size::Integer)
    logmsg("writeListBegin etype: $etype, size: $size")
    writeByte(p, etype)
    writeI32(p, size)
    nothing
end

function writeSetBegin(p::TBinaryProtocol, etype::Int32, size::Integer)
    logmsg("writeSetBegin etype: $etype, size: $size")
    writeByte(p, etype)
    writeI32(p, size)
    nothing
end

write(p::TBinaryProtocol, b::Bool) = writeByte(p, b ? 1 : 0)
write(p::TBinaryProtocol, i::TBYTE) = (_write_fixed(rawio(p.t), i, true); nothing)
write(p::TBinaryProtocol, i::TI16) = (_write_fixed(rawio(p.t), reinterpret(Uint16,i), true); nothing)
write(p::TBinaryProtocol, i::TI32) = (_write_fixed(rawio(p.t), reinterpret(Uint32,i), true); nothing)
write(p::TBinaryProtocol, i::TI64) = (_write_fixed(rawio(p.t), reinterpret(Uint64,i), true); nothing)
write(p::TBinaryProtocol, d::TDOUBLE) = (_write_fixed(rawio(p.t), reinterpret(Uint64,d), true); nothing)
write(p::TBinaryProtocol, a::Array{Uint8,1}) = write(rawio(p.t), a)
write(p::TBinaryProtocol, s::ASCIIString) = (writeI32(p, length(s)); write(p, s.data); nothing)
write(p::TBinaryProtocol, s::UTF8String) = (writeI32(p, length(s)); write(p, s.data); nothing)

function readMessageBegin(p::TBinaryProtocol)
    logmsg("readMessageBegin")
    sz = readI32(p)
    if sz < 0
        version = sz & BINARY_VERSION_MASK
        (version != BINARY_VERSION_1) && throw(TProtocolException(ProtocolExceptionType.BAD_VERSION, "Bad version in readMessageBegin: $sz"))
        typ = int32(sz & BINARY_TYPE_MASK)
        name = readString(p)
        seqid = readI32(p)
    else
        p.strictRead && throw(TProtocolException(ProtocolExceptionType.BAD_VERSION, "No protocol version header"))
        name =  bytestring(read(p, Array(Uint8, sz)))
        typ = int32(readByte(p))
        seqid = readI32(p)
    end
    logmsg("readMessageBegin read name: $name, mtyp: $typ, seqid: $seqid")
    (name, typ, seqid)
end

function readFieldBegin(p::TBinaryProtocol)
    logmsg("readFieldBegin")
    typ = readByte(p)
    logmsg("readFieldBegin, typ: $typ")
    (nothing, typ, (typ == TType.STOP) ? int16(0) : readI16(p))
end
readFieldStop(p::TBinaryProtocol) = readByte(p)
readMapBegin(p::TBinaryProtocol) = (readByte(p), readByte(p), readI32(p))
readListBegin(p::TBinaryProtocol) = (readByte(p), readI32(p))
readSetBegin(p::TBinaryProtocol) = (readByte(p), readI32(p))

read(p::TBinaryProtocol, ::Type{Bool}) = (0x0 != readByte(p))
read(p::TBinaryProtocol, ::Type{TBYTE}) = _read_fixed(rawio(p.t), uint8(0), 1, true)
read(p::TBinaryProtocol, ::Type{TI16}) = reinterpret(TI16, _read_fixed(rawio(p.t), uint16(0), 2, true))
read(p::TBinaryProtocol, ::Type{TI32}) = reinterpret(TI32, _read_fixed(rawio(p.t), uint32(0), 4, true))
read(p::TBinaryProtocol, ::Type{TI64}) = reinterpret(TI64, _read_fixed(rawio(p.t), uint64(0), 8, true))
read(p::TBinaryProtocol, ::Type{TDOUBLE}) = reinterpret(TDOUBLE, _read_fixed(rawio(p.t), uint64(0), 8, true))
read(p::TBinaryProtocol, a::Array{Uint8,1}) = read!(rawio(p.t), a)
read(p::TBinaryProtocol, ::Type{ASCIIString}) = bytestring(read(p, Array(Uint8, readI32(p))))
read(p::TBinaryProtocol, ::Type{UTF8String}) = bytestring(read(p, Array(Uint8, readI32(p))))

# ==========================================
# Binary Protocol End
# ==========================================


# ==========================================
# Compact Protocol Begin
# ==========================================
type _enum_CType
    STOP::Uint8
    TRUE::Uint8
    FALSE::Uint8
    BYTE::Uint8
    I16::Uint8
    I32::Uint8
    I64::Uint8
    DOUBLE::Uint8
    BINARY::Uint8
    LIST::Uint8
    SET::Uint8
    MAP::Uint8
    STRUCT::Uint8
end
const CType = _enum_CType(0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C)

const CTYPE_TO_TTYPE = [TType.STOP, TType.BOOL, TType.BOOL, TType.BYTE, TType.I16, TType.I32, TType.I64, TType.DOUBLE, TType.STRING, TType.LIST, TType.SET, TType.MAP, TType.STRUCT]
const TTYPE_TO_CTYPE = [CType.STOP, 0xff, CType.TRUE, CType.BYTE, CType.DOUBLE, Nothing, CType.I16, Nothing, CType.I32, Nothing, CType.I64, CType.BINARY, CType.STRUCT, CType.MAP, CType.SET, CType.LIST, Nothing, Nothing]

const COMPACT_PROTOCOL_ID       = 0x82
const COMPACT_VERSION           = 1
const COMPACT_VERSION_MASK      = 0x1f
const COMPACT_TYPE_MASK         = 0xe0
const COMPACT_TYPE_SHIFT_AMOUNT = 5

type _enum_CState
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
const CState = _enum_CState(int32(0), int32(1), int32(2), int32(3), int32(4), int32(5), int32(6), int32(7), int32(8))


type TCompactProtocol <: TProtocol
    t::TTransport
    state::Int32
    last_fid::Int16
    bool_fid::Int16
    bool_value::Uint8
    structs::Array{Tuple,1}
    containers::Array{Int32,1}

    TCompactProtocol(t::TTransport) = new(t, CState.CLEAR, 0, 0, 0, Tuple[], Int32[])
end

writeVarint(p::TCompactProtocol, i::Integer) = (_write_uleb(rawio(p.t), i); nothing)
readVarint{T <: Integer}(p::TCompactProtocol, t::Type{T}) = _read_uleb(rawio(p.t), t)

chkstate(p, s) = !(p.state in s) && (logmsg("chkstate: $(p.state) vs. $s"); error("Internal error. Incorrect state."))
byte2ctype(byte) = (byte & 0x0f)
byte2ttype(byte) = CTYPE_TO_TTYPE[byte2ctype(byte)+1]

function writeMessageBegin(p::TCompactProtocol, name::String, mtype::Int32, seqid::Integer)
    logmsg("writeMessageBegin name: $name, mtype: $mtype, seqid: $seqid")
    chkstate(p, CState.CLEAR)
    writeByte(p, COMPACT_PROTOCOL_ID)
    writeByte(p, COMPACT_VERSION | (mtype << COMPACT_TYPE_SHIFT_AMOUNT))
    writeVarint(p, seqid)
    writeString(p, name)
    p.state = CState.VALUE_WRITE
    nothing
end

function writeMessageEnd(p::TCompactProtocol)
    chkstate(p, CState.VALUE_WRITE)
    p.state = CState.CLEAR
    nothing
end

function writeStructBegin(p::TCompactProtocol, name::String)
    chkstate(p, [CState.CLEAR, CState.CONTAINER_WRITE, CState.VALUE_WRITE])
    push!(p.structs, (p.state, p.last_fid))
    p.state = CState.FIELD_WRITE
    p.last_fid = int16(0)
    nothing
end

function writeStructEnd(p::TCompactProtocol)
    chkstate(p, CState.FIELD_WRITE)
    (p.state, p.last_fid) = pop!(p.structs)
    nothing
end
 
function writeFieldStop(p::TCompactProtocol)
    writeByte(p, 0)
    nothing
end

function writeFieldHeader(p::TCompactProtocol, mtype::Uint8, fid::Int16)
    delta = fid - p.last_fid
    if 0 < delta <= 15
      writeByte(p, uint8(delta << 4 | mtype))
    else
      writeByte(p, mtype)
      writeI16(p, fid)
    end
    p.last_fid = fid
    nothing
end

function writeFieldBegin(p::TCompactProtocol, name::String, ttype::Int32, fid::Integer)
    chkstate(p, CState.FIELD_WRITE)
    if ttype == TType.BOOL
      p.state = CState.BOOL_WRITE
      p.bool_fid = fid
    else
      p.state = CState.VALUE_WRITE
      writeFieldHeader(p, TTYPE_TO_CTYPE[ttype+1], int16(fid))
    end
    nothing
end

function writeFieldEnd(p::TCompactProtocol)
    chkstate(p, [CState.VALUE_WRITE, CState.BOOL_WRITE])
    p.state = CState.FIELD_WRITE
    nothing
end

function writeCollectionsBegin(p::TCompactProtocol, etype::Int32, sz::Int32)
    chkstate(p, [CState.VALUE_WRITE, CState.CONTAINER_WRITE])
    if sz <= 14
        writeByte(p, (sz << 4) | TTYPE_TO_CTYPE[etype+1])
    else
        writeByte(p, 0xf0 | TTYPE_TO_CTYPE[etype+1])
        writeSize(p, sz)
    end
    push!(p.containers, p.state)
    p.state = CState.CONTAINER_WRITE
    nothing
end
writeSetBegin(p::TCompactProtocol, etype::Int32, size::Integer) = writeCollectionsBegin(p, etype, size)
writeListBegin(p::TCompactProtocol, etype::Int32, size::Integer) = writeCollectionsBegin(p, etype, size)

function writeMapBegin(p::TCompactProtocol, ktype::Int32, vtype::Int32, size::Integer)
    chkstate(p, [CState.VALUE_WRITE, CState.CONTAINER_WRITE])
    if size == 0
        writeByte(p, 0)
    else
        writeSize(p, size)
        writeByte(p, (TTYPE_TO_CTYPE[ktype+1] << 4) | TTYPE_TO_CTYPE[vtype+1])
    end
    push!(p.containers, p.state)
    p.state = CState.CONTAINER_WRITE
    nothing
end

function writeCollectionEnd(p::TCompactProtocol)
    chkstate(p, CState.CONTAINER_WRITE)
    p.state = pop!(p.containers)
    nothing
end

writeMapEnd(p::TCompactProtocol) = writeCollectionEnd(p)
writeListEnd(p::TCompactProtocol) = writeCollectionEnd(p)
writeSetEnd(p::TCompactProtocol) = writeCollectionEnd(p)

function writeBool(p::TCompactProtocol, b::Bool)
    if p.state == CState.BOOL_WRITE
        ctype = b ? CType.TRUE : CType.FALSE
        writeFieldHeader(p, ctype, p.bool_fid)
    elseif p.state == CState.CONTAINER_WRITE
        writeByte(p, b ? CType.TRUE : CType.FALSE)
    else
      error("Invalid state in compact protocol")
    end
end

writeSize(p::TCompactProtocol, sz::Integer) = writeVarint(p, int32(sz))

write(p::TCompactProtocol, i::TBYTE) = (_write_fixed(rawio(p.t), i, true); nothing)
write(p::TCompactProtocol, i::TI16) = (_write_zigzag(rawio(p.t), i); nothing)
write(p::TCompactProtocol, i::TI32) = (_write_zigzag(rawio(p.t), i); nothing)
write(p::TCompactProtocol, i::TI64) = (_write_zigzag(rawio(p.t), i); nothing)
write(p::TCompactProtocol, d::TDOUBLE) = (_write_fixed(rawio(p.t), reinterpret(Uint64,d), false); nothing)
write(p::TCompactProtocol, a::Array{Uint8,1}) = write(rawio(p.t), a)
write(p::TCompactProtocol, s::ASCIIString) = (writeSize(p, length(s)); write(p, s.data); nothing)
write(p::TCompactProtocol, s::UTF8String) = (writeSize(p, length(s)); write(p, s.data); nothing)

function readMessageBegin(p::TCompactProtocol)
    logmsg("readMessageBegin")
    chkstate(p, CState.CLEAR)
    proto_id = readByte(p)
    (proto_id != COMPACT_PROTOCOL_ID) && error("Incorrect protocol id $proto_id")
    ver_type = readByte(p)
    typ = (ver_type & COMPACT_TYPE_MASK) >> COMPACT_TYPE_SHIFT_AMOUNT
    version = ver_type & COMPACT_VERSION_MASK
    (version != COMPACT_VERSION) && error("Incorrect version $version. Need $COMPACT_VERSION")
    seqid = readVarint(p, Int32)
    name = readString(p)
    logmsg("readMessageBegin read name: $name, mtyp: $typ, seqid: $seqid")
    (name, int32(typ), seqid)
end

function readMessageEnd(p::TCompactProtocol)
    logmsg("readMessageEnd")
    chkstate(p, CState.CLEAR)
    !isempty(p.structs) && error("Reading message went bad somewhere!")
    nothing
end

function readStructBegin(p::TCompactProtocol)
    chkstate(p, [CState.CLEAR, CState.CONTAINER_READ, CState.VALUE_READ])
    push!(p.structs, (p.state, p.last_fid))
    p.state = CState.FIELD_READ
    p.last_fid = 0
    nothing
end

function readStructEnd(p::TCompactProtocol)
    logmsg("readStructEnd")
    chkstate(p, CState.FIELD_READ)
    (p.state, p.last_fid) = pop!(p.structs)
    nothing
end

function readFieldBegin(p::TCompactProtocol)
    logmsg("readFieldBegin")
    chkstate(p, CState.FIELD_READ)
    typ = readByte(p)
    ((typ & 0x0f) == TType.STOP) && (return (nothing, uint8(0), int16(0)))
    delta = (typ >> 4)
    fid = (delta == 0) ? readI16(p) : int16(p.last_fid + delta)
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
    logmsg("readFieldBegin, typ: $(byte2ttype(typ))")
    (nothing, byte2ttype(typ), fid)
end

function readFieldEnd(p::TCompactProtocol)
    logmsg("readFieldEnd")
    chkstate(p, [CState.VALUE_READ, CState.BOOL_READ])
    p.state = CState.FIELD_READ
    nothing
end

function readCollectionBegin(p::TCompactProtocol)
    chkstate(p, [CState.CONTAINER_READ, CState.VALUE_READ])
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
    chkstate(p, [CState.CONTAINER_READ, CState.VALUE_READ])
    size = readSize(p)
    types = (size > 0) ? readByte(p) : 0
    vtype = byte2ttype(types)
    ktype = byte2ttype(types >> 4)
    push!(p.containers, p.state)
    p.state = CState.CONTAINER_READ
    (ktype, vtype, size)
end

function readCollectionEnd(p::TCompactProtocol)
    chkstate(p, CState.CONTAINER_READ)
    p.state = pop!(p.containers)
    nothing
end

function read(p::TCompactProtocol, ::Type{Bool})
    chkstate(p, [CState.CONTAINER_READ, CState.BOOL_READ])
    (p.state == CState.BOOL_READ) && (return (p.bool_value == CType.TRUE))
    (p.state == CState.CONTAINER_READ) && (return (readByte(p) == CType.TRUE))
end

readSize(p::TCompactProtocol) = readVarint(p, Int32)

read(p::TCompactProtocol, t::Type{TBYTE}) = _read_fixed(rawio(p.t), uint8(0), 1, true)
read(p::TCompactProtocol, t::Type{TI16}) = _read_zigzag(rawio(p.t), t)
read(p::TCompactProtocol, t::Type{TI32}) = _read_zigzag(rawio(p.t), t)
read(p::TCompactProtocol, t::Type{TI64}) = _read_zigzag(rawio(p.t), t)
read(p::TCompactProtocol, t::Type{TDOUBLE}) = reinterpret(TDOUBLE, _read_fixed(rawio(p.t), uint64(0), 8, false))
read(p::TCompactProtocol, a::Array{Uint8,1}) = read!(rawio(p.t), a)
read(p::TCompactProtocol, t::Type{ASCIIString}) = bytestring(read(p, Array(Uint8, readSize(p))))
read(p::TCompactProtocol, t::Type{UTF8String}) = bytestring(read(p, Array(Uint8, readSize(p))))

# ==========================================
# Compact Protocol End
# ==========================================

