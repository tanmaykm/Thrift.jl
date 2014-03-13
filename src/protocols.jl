
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

type TBinaryProtocol
    t::TTransport
    strict_read::Bool
    strict_write::Bool

    TBinaryProtocol(t::TTransport, strict_read::Bool=true, strict_write::Bool=true) = new(t, strict_read, strict_write)    
end


function writeMessageBegin(p::TBinaryProtocol, name::String, ttype::Int32, seqid::Integer)
    if p.strict_write
        writeI32(p, BINARY_VERSION_1 | ttype)
        writeString(p, name)
        writeI32(p, seqid)
    else
        writeString(p, name)
        writeByte(p, ttype)
        writeI32(p, seqid)
    end
end

function writeFieldBegin(p::TProtocol, name::String, ttype::Int32, fid::Integer)
    writeByte(p, ttype)
    writeI16(p, fid)
    nothing
end

writeFieldStop(p::TProtocol) = writeByte(p, TType.STOP)

function writeMapBegin(p::TProtocol, ktype::Int32, vtype::Int32, size::Integer)
    writeByte(p, ktype)
    writeByte(p, vtype)
    writeI32(p, size)
    nothing
end

function writeListBegin(p::TProtocol, etype::Int32, size::Integer)
    writeByte(p, etype)
    writeI32(p, size)
    nothing
end

function writeSetBegin(p::TProtocol, etype::Int32, size::Integer)
    writeByte(p, etype)
    writeI32(p, size)
    nothing
end

write(p::TProtocol, b::Bool) = writeByte(p, b ? 1 : 0)
write(p::TProtocol, i::TBYTE) = (_write_fixed(rawio(p.t), i, true); nothing)
write(p::TProtocol, i::TI16) = (_write_fixed(rawio(p.t), reinterpret(Uint16,i), true); nothing)
write(p::TProtocol, i::TI32) = (_write_fixed(rawio(p.t), reinterpret(Uint32,i), true); nothing)
write(p::TProtocol, i::TI64) = (_write_fixed(rawio(p.t), reinterpret(Uint64,i), true); nothing)
write(p::TProtocol, d::TDOUBLE) = (_write_fixed(rawio(p.t), reinterpret(Uint64,i), true); nothing)
write(p::TProtocol, a::Array{Uint8,1}) = write(rawio(p.t), a)
write(p::TProtocol, s::ByteString) = (writeI32(p, length(s)); write(p, s.data); nothing)

read(p::TProtocol, ::Type{Bool}) = (0x0 != readByte(p))
read(p::TProtocol, ::Type{TBYTE}) = _read_fixed(rawio(p.t), uint8(0), 1, true)
read(p::TProtocol, ::Type{TI16}) = reinterpret(TI16, _read_fixed(rawio(p.t), uint16(0), 2, true))
read(p::TProtocol, ::Type{TI32}) = reinterpret(TI32, _read_fixed(rawio(p.t), uint32(0), 4, true))
read(p::TProtocol, ::Type{TI64}) = reinterpret(TI64, _read_fixed(rawio(p.t), uint64(0), 8, true))
read(p::TProtocol, ::Type{TDOUBLE}) = reinterpret(TDOUBLE, _read_fixed(rawio(p.t), uint64(0), 1, true))
read(p::TProtocol, a::Array{Uint8,1}) = read(rawio(p.t), a)
read(p::TProtocol, ::Type{ByteString}) = bytestring(read(p, Array(Uint8, readI32(p))))



