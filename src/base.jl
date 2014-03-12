##
# Base Thrift type system
type TSTOP end
typealias TVOID     Nothing
typealias TBOOL     Bool
typealias TBYTE     Uint8
typealias TI08      Uint8
typealias TDOUBLE   Float64
typealias TI16      Int16
typealias TI32      Int32
typealias TI64      Int64
typealias TSTRING   ASCIIString
typealias TUTF7     ASCIIString
typealias TSTRUCT   Any
typealias TMAP      Dict
typealias TSET      Set
typealias TLIST     Array
typealias TUTF8     UTF8String
typealias TUTF16    UTF16String

type _enum_TTypes
    STOP::Int32
    VOID::Int32
    BOOL::Int32
    BYTE::Int32
    I08::Int32
    DOUBLE::Int32
    I16::Int32
    I32::Int32
    I64::Int32
    STRING::Int32
    UTF7::Int32
    STRUCT::Int32
    MAP::Int32
    SET::Int32
    LIST::Int32
    UTF8::Int32
    UTF16::Int32
end

const TType = _enum_TTypes(0,    1,      2,      3,3,     4,              6,             8,            10,    11,11,     12,      13,    14,     15,      16,    17)
#                        0       1       2       3        4       5       6     7        8     9       10     11         12       13     14      15       16     17
const _TTypeNames   = ["STOP", "VOID", "BOOL", "BYTE", "DOUBLE", "",    "I16", "",     "I32", "",     "I64", "STRING", "STRUCT", "MAP", "SET", "LIST", "UTF8", "UTF16"]
const _TJTypes    =   [TSTOP,  TVOID,  TBOOL,  TBYTE,  TDOUBLE, Nothing, TI16, Nothing, TI32, Nothing, TI64,  TSTRING,  TSTRUCT,  TMAP,  TSET,  TLIST,  TUTF8,  TUTF16]

thrift_type_name(typ::Int32) = _TTypeNames[typ+1]

julia_type(typ::Int32) = _TJTypes[typ+1]

thrift_type(::Type{TSTOP})          = int32(0)
thrift_type(::Type{TVOID})          = int32(1)
thrift_type(::Type{TBOOL})          = int32(2)
thrift_type(::Type{TBYTE})          = int32(3)
thrift_type(::Type{TDOUBLE})        = int32(4)
thrift_type(::Type{TI16})           = int32(6)
thrift_type(::Type{TI32})           = int32(8)
thrift_type(::Type{TI64})           = int32(10)
thrift_type(::Type{TSTRING})        = int32(11)
thrift_type{T<:Any}(::Type{T})      = int32(12)
thrift_type{T<:Dict}(::Type{T})     = int32(13)
thrift_type{T<:Set}(::Type{T})      = int32(14)
thrift_type{T<:Array}(::Type{T})    = int32(15)
thrift_type(::Type{TUTF8})          = int32(16)
thrift_type(::Type{TUTF16})         = int32(17)

const _container_type_ids = [TType.STRUCT, TType.MAP, TType.SET, TType.LIST]
const _container_types    = [TSTRUCT, TMAP, TSET, TLIST]
iscontainer(typ::Int32)   = (typ in _container_type_ids)
iscontainer{T}(typ::Type{T})    = iscontainer(thrift_type(typ))


##
# base transport types
abstract TTransportBase
abstract TServerTransportBase <: TTransportBase


##
# base protocol types
instantiate(t::Type) = (t.abstract) ? error("can not instantiate abstract type $t") : ccall(:jl_new_struct_uninit, Any, (Any,Any...), t)

abstract TProtocolBase

##
# base protocol read and write methods
for _typ in _TJTypes
    if !iscontainer(_typ)
        @eval begin
            write(p::TProtocolBase, val::$(_typ)) = nothing
            read(p::TProtocolBase, ::Type{$(_typ)}) = nothing
            skip(p::TProtocolBase, ::Type{$(_typ)}) = read(p, $(_typ))
        end
    end
end

writeMessageBegin(p::TProtocolBase, name::String, ttype::Int32, seqid::Integer)    = nothing
writeMessageEnd(p::TProtocolBase)                                                  = nothing
writeStructBegin(p::TProtocolBase, name::String)                                   = nothing
writeStructEnd(p::TProtocolBase)                                                   = nothing
writeFieldBegin(p::TProtocolBase, name::String, ttype::Int32, fid::Integer)        = nothing 
writeFieldEnd(p::TProtocolBase)                                                    = nothing
writeFieldStop(p::TProtocolBase)                                                   = nothing
writeMapBegin(p::TProtocolBase, ktype::Int32, vtype::Int32, size::Integer)         = nothing
writeMapEnd(p::TProtocolBase)                                                      = nothing
writeListBegin(p::TProtocolBase, etype::Int32, size::Integer)                      = nothing
writeListEnd(p::TProtocolBase)                                                     = nothing
writeSetBegin(p::TProtocolBase, etype::Int32, size::Integer)                       = nothing
writeSetEnd(p::TProtocolBase)                                                      = nothing
writeBool(p::TProtocolBase, val)                                                   = write(p, convert(TBOOL, val))
writeByte(p::TProtocolBase, val)                                                   = write(p, convert(TBYTE, val))
writeI16(p::TProtocolBase, val)                                                    = write(p, convert(TI16, val))
writeI32(p::TProtocolBase, val)                                                    = write(p, convert(TI32, val))
writeI64(p::TProtocolBase, val)                                                    = write(p, convert(TI64, val))
writeDouble(p::TProtocolBase, val)                                                 = write(p, convert(TDOUBLE, val))
writeString(p::TProtocolBase, val)                                                 = write(p, bytestring(val))

readMessageBegin(p::TProtocolBase)     = nothing
readMessageEnd(p::TProtocolBase)       = nothing
readStructBegin(p::TProtocolBase)      = nothing
readStructEnd(p::TProtocolBase)        = nothing
readFieldBegin(p::TProtocolBase)       = nothing
readFieldEnd(p::TProtocolBase)         = nothing
readMapBegin(p::TProtocolBase)         = nothing
readMapEnd(p::TProtocolBase)           = nothing
readListBegin(p::TProtocolBase)        = nothing
readListEnd(p::TProtocolBase)          = nothing
readSetBegin(p::TProtocolBase)         = nothing
readSetEnd(p::TProtocolBase)           = nothing
readBool(p::TProtocolBase)             = read(p, TBOOL)
readByte(p::TProtocolBase)             = read(p, TBYTE)
readI16(p::TProtocolBase)              = read(p, TI16)
readI32(p::TProtocolBase)              = read(p, TI32)
readI64(p::TProtocolBase)              = read(p, TI64)
readDouble(p::TProtocolBase)           = read(p, TDOUBLE)
readString(p::TProtocolBase)           = read(p, ByteString)


function skip(p::TProtocolBase, ::Type{TSTRUCT})
    name = readStructBegin(p)
    while true
        (name, ttype, id) = readFieldBegin(p)
        (ttype == TType.STOP) && break
        skip(t, julia_type(ttype))
        readFieldEnd(p)
    end
    readStructEnd(p)
    return
end

function read(p::TProtocolBase, ::Type{TSTRUCT}, val=nothing)
    name = readStructBegin(p)
    structtyp = eval(symbol(name)) 
    if val == nothing 
        val = instantiate(structtyp)
    else
        !issubtype(typeof(val), structtyp) && error("can not read $structtyp into $(typeof(val))")
    end

    while true
        (name, ttype, id) = readFieldBegin(p)
        fldname = symbol(name)
        (ttype == TType.STOP) && break
        jtyp = julia_type(ttype)
        if iscontainer(ttype)
            if !isdefined(val, fldname) 
                setfield!(val, fldname, read(p, jtyp))
            else
                read(p, jtyp, getfield(val, fldname))
            end
        else
            setfield!(val, fldname, read(p, jtyp))
        end
    end
    readStructEnd(p)
    val
end

function write(p::TProtocolBase, val::TSTRUCT)
    structtyp = typeof(val)
    writeStructBegin(p, string(structtyp))
    names = structtyp.names
    types = structtyp.types

    # TODO: need meta and fill information
    for idx in 1:length(names)
        writeFieldBegin(p, string(names[idx]), thrift_type(types[idx]), idx)
        write(p, getfield(val, names[idx]))
        writeFieldEnd(p)
    end
    writeStructEnd(p)
    nothing
end

function skip(p::TProtocolBase, ::Type{TMAP})
    (ktype, vtype, size) = readMapBegin(p)
    jktype = julia_type(ktype)
    jvtype = julia_type(vtype)
    for i in 1:size
        skip(p, jktype)
        skip(p, jvtype)
    end
    readMapEnd(p)
    return
end

function read(p::TProtocolBase, ::Type{TMAP}, val=nothing)
    (ktype, vtype, size) = readMapBegin(p)
    jktype = julia_type(ktype)
    jvtype = julia_type(vtype)

    if val == nothing
        val = Dict{jktype,jvtype}()
    else
        (_ktype, _vtype) = eltype(val)
        (!issubtype(jktype, _ktype) || !issubtype(jvtype, _vtype)) && error("can not read Dict{$jktype,$jvtype} into $(typeof(val))")
    end

    for i in 1:size
        k = read(p, jktype)
        v = read(p, jvtype)
        val[k] = v
    end
    readMapEnd(p)
    val
end

function write(p::TProtocolBase, val::TMAP)
    (ktype,vtype) = eltype(val)
    writeMapBegin(p, thrift_type(ktype), thrift_type(vtype), length(val))
    for (k,v) in val
        write(p, k)
        write(p, v)
    end
    writeMapEnd(p)
end

function skip(p::TProtocolBase, ::Type{TSET})
    (etype, size) = readSetBegin(p)
    jetype = julia_type(etype)
    for i in 1:size
        skip(p, jetype)
    end
    readSetEnd(p)
end

function read(p::TProtocolBase, ::Type{TSET}, val=nothing)
    (etype, size) = readSetBegin(p)
    jetype = julia_type(etype)
    if val == nothing
        val = Set{jetype}()
    else
        !issubtype(jetype, eltype(val)) && error("can not read $jetype into $(typeof(val))")
    end

    for i in 1:size
        add!(val, read(p, jetype))
    end
    readSetEnd(p)
    val
end

function write(p::TProtocolBase, val::TSET)
    writeSetBegin(p, thrift_type(eltype(val)), length(val))
    # TODO: need meta to convert type correctly
    for v in val
        write(p, v)
    end
    writeSetEnd(p)
end

function skip(p::TProtocolBase, ::Type{TLIST})
    (etype, size) = readListBegin(p)
    jetype = julia_type(etype)
    for i in 1:size
        skip(p, jetype)
    end
    readListEnd(p)
end

function read(p::TProtocolBase, ::Type{TLIST}, val=nothing)
    (etype, size) = readListBegin(p)
    jetype = julia_type(etype)
    if val == nothing
        val = Array(jetype,0)
    else
        !issubtype(eltype(val), jetype) && error("can not read $jetype into $(typeof(val))")
    end

    for i in 1:size
        push!(val, read(p, jetype))
    end
    readListEnd(p)
end

function write(p::TProtocolBase, val::TLIST)
    writeListBegin(p, thrift_type(eltype(val)), length(val))
    # TODO: need meta to convert type correctly
    for v in val
        write(p, v)
    end
    writeListEnd(p)
    nothing
end


