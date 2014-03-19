
type _enum_TProtocolExceptionTypes
    UNKNOWN::Int32
    INVALID_DATA::Int32
    NEGATIVE_SIZE::Int32
    SIZE_LIMIT::Int32
    BAD_VERSION::Int32
end

const ProtocolExceptionType = _enum_TProtocolExceptionTypes(0, 1, 2, 3, 4)

type TProtocolException
    typ::Int32
    message::String

    TProtocolException(typ::Int32=ProtocolExceptionType.UNKNOWN, message::String="") = new(typ, message)
end



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
write(p::TBinaryProtocol, d::TDOUBLE) = (_write_fixed(rawio(p.t), reinterpret(Uint64,i), true); nothing)
write(p::TBinaryProtocol, a::Array{Uint8,1}) = write(rawio(p.t), a)
write(p::TBinaryProtocol, s::ASCIIString) = (writeI32(p, length(s)); write(p, s.data); nothing)
write(p::TBinaryProtocol, s::UTF8String) = (writeI32(p, length(s)); write(p, s.data); nothing)

function readMessageBegin(p::TBinaryProtocol)
    logmsg("readMessageBegin")
    sz = readI32(p)
    if sz < 0
        version = sz & BINARY_VERSION_MASK
        (version != BINARY_VERSION_1) && throw(TProtocolException(ProtocolExceptionType.BAD_VERSION, "Bad version in readMessageBegin: $sz"))
        typ = sz & BINARY_TYPE_MASK
        name = readString(p)
        seqid = readI32(p)
    else
        p.strictRead && throw(TProtocolException(ProtocolExceptionType.BAD_VERSION, "No protocol version header"))
        name =  bytestring(read(p, Array(Uint8, sz)))
        typ = readByte(p)
        seqid = readI32(p)
    end
    logmsg("readMessageBegin read name: $name, mtyp: $typ, seqid: $seqid")
    (name, typ, seqid)
end

function readFieldBegin(p::TBinaryProtocol)
    logmsg("readFieldBegin")
    typ = readByte(p)
    logmsg("readFieldBegin, typ: $typ")
    (nothing, typ, (typ == TType.STOP) ? 0 : readI16(p))
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
read(p::TBinaryProtocol, ::Type{TDOUBLE}) = reinterpret(TDOUBLE, _read_fixed(rawio(p.t), uint64(0), 1, true))
read(p::TBinaryProtocol, a::Array{Uint8,1}) = read!(rawio(p.t), a)
read(p::TBinaryProtocol, ::Type{ASCIIString}) = bytestring(read(p, Array(Uint8, readI32(p))))
read(p::TBinaryProtocol, ::Type{UTF8String}) = bytestring(read(p, Array(Uint8, readI32(p))))



