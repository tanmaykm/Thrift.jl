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
# base processor method
abstract TProcessor
process(tp::TProcessor) = nothing


##
# base transport types
abstract TTransport
abstract TServerTransport <: TTransport

##
# base server type
abstract TServer

##
# base protocol types
abstract TProtocol

##
# base protocol read and write methods
instantiate(t::Type) = (t.abstract) ? error("can not instantiate abstract type $t") : ccall(:jl_new_struct_uninit, Any, (Any,Any...), t)
for _typ in _TJTypes
    if !iscontainer(_typ)
        @eval begin
            write(p::TProtocol, val::$(_typ)) = nothing
            read(p::TProtocol, ::Type{$(_typ)}) = nothing
            skip(p::TProtocol, ::Type{$(_typ)}) = read(p, $(_typ))
        end
    end
end

writeMessageBegin(p::TProtocol, name::String, ttype::Int32, seqid::Integer)    = nothing
writeMessageEnd(p::TProtocol)                                                  = nothing
writeStructBegin(p::TProtocol, name::String)                                   = nothing
writeStructEnd(p::TProtocol)                                                   = nothing
writeFieldBegin(p::TProtocol, name::String, ttype::Int32, fid::Integer)        = nothing 
writeFieldEnd(p::TProtocol)                                                    = nothing
writeFieldStop(p::TProtocol)                                                   = nothing
writeMapBegin(p::TProtocol, ktype::Int32, vtype::Int32, size::Integer)         = nothing
writeMapEnd(p::TProtocol)                                                      = nothing
writeListBegin(p::TProtocol, etype::Int32, size::Integer)                      = nothing
writeListEnd(p::TProtocol)                                                     = nothing
writeSetBegin(p::TProtocol, etype::Int32, size::Integer)                       = nothing
writeSetEnd(p::TProtocol)                                                      = nothing
writeBool(p::TProtocol, val)                                                   = write(p, convert(TBOOL, val))
writeByte(p::TProtocol, val)                                                   = write(p, convert(TBYTE, val))
writeI16(p::TProtocol, val)                                                    = write(p, convert(TI16, val))
writeI32(p::TProtocol, val)                                                    = write(p, convert(TI32, val))
writeI64(p::TProtocol, val)                                                    = write(p, convert(TI64, val))
writeDouble(p::TProtocol, val)                                                 = write(p, convert(TDOUBLE, val))
writeString(p::TProtocol, val)                                                 = write(p, bytestring(val))

readMessageBegin(p::TProtocol)     = nothing
readMessageEnd(p::TProtocol)       = nothing
readStructBegin(p::TProtocol)      = nothing
readStructEnd(p::TProtocol)        = nothing
readFieldBegin(p::TProtocol)       = nothing
readFieldEnd(p::TProtocol)         = nothing
readMapBegin(p::TProtocol)         = nothing
readMapEnd(p::TProtocol)           = nothing
readListBegin(p::TProtocol)        = nothing
readListEnd(p::TProtocol)          = nothing
readSetBegin(p::TProtocol)         = nothing
readSetEnd(p::TProtocol)           = nothing
readBool(p::TProtocol)             = read(p, TBOOL)
readByte(p::TProtocol)             = read(p, TBYTE)
readI16(p::TProtocol)              = read(p, TI16)
readI32(p::TProtocol)              = read(p, TI32)
readI64(p::TProtocol)              = read(p, TI64)
readDouble(p::TProtocol)           = read(p, TDOUBLE)
readString(p::TProtocol)           = read(p, ByteString)


function skip(p::TProtocol, ::Type{TSTRUCT})
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

function read(p::TProtocol, ::Type{TSTRUCT}, val=nothing)
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

function write(p::TProtocol, val::TSTRUCT)
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

function skip(p::TProtocol, ::Type{TMAP})
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

function read(p::TProtocol, ::Type{TMAP}, val=nothing)
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

function write(p::TProtocol, val::TMAP)
    (ktype,vtype) = eltype(val)
    writeMapBegin(p, thrift_type(ktype), thrift_type(vtype), length(val))
    for (k,v) in val
        write(p, k)
        write(p, v)
    end
    writeMapEnd(p)
end

function skip(p::TProtocol, ::Type{TSET})
    (etype, size) = readSetBegin(p)
    jetype = julia_type(etype)
    for i in 1:size
        skip(p, jetype)
    end
    readSetEnd(p)
end

function read(p::TProtocol, ::Type{TSET}, val=nothing)
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

function write(p::TProtocol, val::TSET)
    writeSetBegin(p, thrift_type(eltype(val)), length(val))
    # TODO: need meta to convert type correctly
    for v in val
        write(p, v)
    end
    writeSetEnd(p)
end

function skip(p::TProtocol, ::Type{TLIST})
    (etype, size) = readListBegin(p)
    jetype = julia_type(etype)
    for i in 1:size
        skip(p, jetype)
    end
    readListEnd(p)
end

function read(p::TProtocol, ::Type{TLIST}, val=nothing)
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

function write(p::TProtocol, val::TLIST)
    writeListBegin(p, thrift_type(eltype(val)), length(val))
    # TODO: need meta to convert type correctly
    for v in val
        write(p, v)
    end
    writeListEnd(p)
    nothing
end


##
# Exception types
type TException <: Exception
    message::String
end

type _enum_TApplicationExceptionTypes
    UNKNOWN::Int32
    UNKNOWN_METHOD::Int32
    INVALID_MESSAGE_TYPE::Int32
    WRONG_METHOD_NAME::Int32
    BAD_SEQUENCE_ID::Int32
    MISSING_RESULT::Int32 
    INTERNAL_ERROR::Int32
    PROTOCOL_ERROR::Int32
    INVALID_TRANSFORM::Int32
    INVALID_PROTOCOL::Int32
    UNSUPPORTED_CLIENT_TYPE::Int32
end

const ApplicationExceptionType = _enum_TApplicationExceptionTypes(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
const _appex_msgs = [
    "Default (unknown) TApplicationException",
    "Unknown method",
    "Invalid message type",
    "Wrong method name",
    "Bad sequence ID",
    "Missing result",
    "Internal error",
    "Protocol error",
    "Invalid transform",
    "Invalid protocol",
    "Unsupported client type"
]   
    
type TApplicationException <: Exception
    typ::Int32
    message::String

    TApplicationException(typ::Int32=ApplicationExceptionType.UNKNOWN, message::String="") = new(typ, isempty(message) ? _appex_msgs[typ+1] : message)
end



##
# Message types
type _enum_TMessageType
    CALL::Int32
    REPLY::Int32
    EXCEPTION::Int32
    ONEWAY::Int32
end 

const MessageType = _enum_TMessageType(1, 2, 3, 4)

