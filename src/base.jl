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
            write(p::TProtocolBase, t::TTransportBase, val::$(_typ)) = nothing
            read(p::TProtocolBase, t::TTransportBase, ::Type{$(_typ)}) = nothing
            skip(p::TProtocolBase, t::TTransportBase, ::Type{$(_typ)}) = read(p, t, $(_typ))
        end
    end
end

writeMessageBegin(p::TProtocolBase, t::TTransportBase, name::String, ttype::Int32, seqid::Integer)    = nothing
writeMessageEnd(p::TProtocolBase, t::TTransportBase)                                                  = nothing
writeStructBegin(p::TProtocolBase, t::TTransportBase, name::String)                                   = nothing
writeStructEnd(p::TProtocolBase, t::TTransportBase)                                                   = nothing
writeFieldBegin(p::TProtocolBase, t::TTransportBase, name::String, ttype::Int32, fid::Integer)        = nothing 
writeFieldEnd(p::TProtocolBase, t::TTransportBase)                                                    = nothing
writeFieldStop(p::TProtocolBase, t::TTransportBase)                                                   = nothing
writeMapBegin(p::TProtocolBase, t::TTransportBase, ktype::Int32, vtype::Int32, size::Integer)         = nothing
writeMapEnd(p::TProtocolBase, t::TTransportBase)                                                      = nothing
writeListBegin(p::TProtocolBase, t::TTransportBase, etype::Int32, size::Integer)                      = nothing
writeListEnd(p::TProtocolBase, t::TTransportBase)                                                     = nothing
writeSetBegin(p::TProtocolBase, t::TTransportBase, etype::Int32, size::Integer)                       = nothing
writeSetEnd(p::TProtocolBase, t::TTransportBase)                                                      = nothing
writeBool(p::TProtocolBase, t::TTransportBase, val)                                                   = write(t, convert(Bool, val))
writeByte(p::TProtocolBase, t::TTransportBase, val)                                                   = write(t, convert(Uint8, val))
writeI16(p::TProtocolBase, t::TTransportBase, val)                                                    = write(t, convert(Int16, val))
writeI32(p::TProtocolBase, t::TTransportBase, val)                                                    = write(t, convert(Int32, val))
writeI64(p::TProtocolBase, t::TTransportBase, val)                                                    = write(t, convert(Int64, val))
writeDouble(p::TProtocolBase, t::TTransportBase, val)                                                 = write(t, convert(Float64, val))
writeString(p::TProtocolBase, t::TTransportBase, val)                                                 = write(t, convert(String, val))

readMessageBegin(p::TProtocolBase, t::TTransportBase)     = nothing
readMessageEnd(p::TProtocolBase, t::TTransportBase)       = nothing
readStructBegin(p::TProtocolBase, t::TTransportBase)      = nothing
readStructEnd(p::TProtocolBase, t::TTransportBase)        = nothing
readFieldBegin(p::TProtocolBase, t::TTransportBase)       = nothing
readFieldEnd(p::TProtocolBase, t::TTransportBase)         = nothing
readMapBegin(p::TProtocolBase, t::TTransportBase)         = nothing
readMapEnd(p::TProtocolBase, t::TTransportBase)           = nothing
readListBegin(p::TProtocolBase, t::TTransportBase)        = nothing
readListEnd(p::TProtocolBase, t::TTransportBase)          = nothing
readSetBegin(p::TProtocolBase, t::TTransportBase)         = nothing
readSetEnd(p::TProtocolBase, t::TTransportBase)           = nothing
readBool(p::TProtocolBase, t::TTransportBase)             = read(t, TBOOL)
readByte(p::TProtocolBase, t::TTransportBase)             = read(t, TBYTE)
readI16(p::TProtocolBase, t::TTransportBase)              = read(t, TI16)
readI32(p::TProtocolBase, t::TTransportBase)              = read(t, TI32)
readI64(p::TProtocolBase, t::TTransportBase)              = read(t, TI64)
readDouble(p::TProtocolBase, t::TTransportBase)           = read(t, TDOUBLE)
readString(p::TProtocolBase, t::TTransportBase)           = read(t, TSTRING)


function skip(p::TProtocolBase, t::TTransportBase, ::Type{TSTRUCT})
    name = readStructBegin(p, t)
    while true
        (name, ttype, id) = readFieldBegin(p, t)
        (ttype == TType.STOP) && break
        skip(t, julia_type(ttype))
        readFieldEnd(p, t)
    end
    readStructEnd(p, t)
    return
end

function read(p::TProtocolBase, t::TTransportBase, ::Type{TSTRUCT}, val=nothing)
    name = readStructBegin(p, t)
    structtyp = eval(symbol(name)) 
    if val == nothing 
        val = instantiate(structtyp)
    else
        !issubtype(typeof(val), structtyp) && error("can not read $structtyp into $(typeof(val))")
    end

    while true
        (name, ttype, id) = readFieldBegin(p, t)
        fldname = symbol(name)
        (ttype == TType.STOP) && break
        jtyp = julia_type(ttype)
        if iscontainer(ttype)
            if !isdefined(val, fldname) 
                setfield!(val, fldname, read(p, t, jtyp))
            else
                read(p, t, jtyp, getfield(val, fldname))
            end
        else
            setfield!(val, fldname, read(p, t, jtyp))
        end
    end
    readStructEnd(p, t)
    val
end

function write(p::TProtocolBase, t::TTransportBase, val::TSTRUCT)
    structtyp = typeof(val)
    writeStructBegin(p, t, string(structtyp))
    names = structtyp.names
    types = structtyp.types

    # TODO: need meta and fill information
    for idx in 1:length(names)
        writeFieldBegin(p, t, string(names[idx]), thrift_type(types[idx]), idx)
        write(p, t, getfield(val, names[idx]))
        writeFieldEnd(p, t)
    end
    writeStructEnd(p, t)
    nothing
end

function skip(p::TProtocolBase, t::TTransportBase, ::Type{TMAP})
    (ktype, vtype, size) = readMapBegin(p, t)
    jktype = julia_type(ktype)
    jvtype = julia_type(vtype)
    for i in 1:size
        skip(p, t, jktype)
        skip(p, t, jvtype)
    end
    readMapEnd(p, t)
    return
end

function read(p::TProtocolBase, t::TTransportBase, ::Type{TMAP}, val=nothing)
    (ktype, vtype, size) = readMapBegin(p, t)
    jktype = julia_type(ktype)
    jvtype = julia_type(vtype)

    if val == nothing
        val = Dict{jktype,jvtype}()
    else
        (_ktype, _vtype) = eltype(val)
        (!issubtype(jktype, _ktype) || !issubtype(jvtype, _vtype)) && error("can not read Dict{$jktype,$jvtype} into $(typeof(val))")
    end

    for i in 1:size
        k = read(p, t, jktype)
        v = read(p, t, jvtype)
        val[k] = v
    end
    readMapEnd(p, t)
    val
end

function write(p::TProtocolBase, t::TTransportBase, val::TMAP)
    (ktype,vtype) = eltype(val)
    writeMapBegin(p, t, thrift_type(ktype), thrift_type(vtype), length(val))
    for (k,v) in val
        write(p, t, k)
        write(p, t, v)
    end
    writeMapEnd(p, t)
end

function skip(p::TProtocolBase, t::TTransportBase, ::Type{TSET})
    (etype, size) = readSetBegin(p, t)
    jetype = julia_type(etype)
    for i in 1:size
        skip(p, t, jetype)
    end
    readSetEnd(p, t)
end

function read(p::TProtocolBase, t::TTransportBase, ::Type{TSET}, val=nothing)
    (etype, size) = readSetBegin(p, t)
    jetype = julia_type(etype)
    if val == nothing
        val = Set{jetype}()
    else
        !issubtype(jetype, eltype(val)) && error("can not read $jetype into $(typeof(val))")
    end

    for i in 1:size
        add!(val, read(p, t, jetype))
    end
    readSetEnd(p, t)
    val
end

function write(p::TProtocolBase, t::TTransportBase, val::TSET)
    writeSetBegin(p, t, thrift_type(eltype(val)), length(val))
    # TODO: need meta to convert type correctly
    for v in val
        write(p, t, v)
    end
    writeSetEnd(p, t)
end

function skip(p::TProtocolBase, t::TTransportBase, ::Type{TLIST})
    (etype, size) = readListBegin(p, t)
    jetype = julia_type(etype)
    for i in 1:size
        skip(p, t, jetype)
    end
    readListEnd(p, t)
end

function read(p::TProtocolBase, t::TTransportBase, ::Type{TLIST}, val=nothing)
    (etype, size) = readListBegin(p, t)
    jetype = julia_type(etype)
    if val == nothing
        val = Array(jetype,0)
    else
        !issubtype(eltype(val), jetype) && error("can not read $jetype into $(typeof(val))")
    end

    for i in 1:size
        push!(val, read(p, t, jetype))
    end
    readListEnd(p, t)
end

function write(p::TProtocolBase, t::TTransportBase, val::TLIST)
    writeListBegin(p, t, thrift_type(eltype(val)), length(val))
    # TODO: need meta to convert type correctly
    for v in val
        write(p, t, v)
    end
    writeListEnd(p, t)
    nothing
end


