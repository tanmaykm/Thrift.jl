# Base Thrift type system
struct TSTOP end
const TVOID     = Nothing
const TBOOL     = Bool
const TBYTE     = UInt8     # TBYTE is actually I8 (signed)
const TDOUBLE   = Float64
const TI16      = Int16
const TI32      = Int32
const TI64      = Int64
const TBINARY   = Vector{UInt8}
const TUTF8     = String
const TSTRING   = Union{TUTF8, TBINARY}
const TSTRUCT   = Any
const TMAP      = Dict
const TSET      = Set
const TLIST     = Array

abstract type TMsg end

struct _enum_TTypes
    STOP::Int32
    VOID::Int32
    BOOL::Int32
    BYTE::Int32
    DOUBLE::Int32
    I16::Int32
    I32::Int32
    I64::Int32
    STRING::Int32
    STRUCT::Int32
    MAP::Int32
    SET::Int32
    LIST::Int32
end

const TType = _enum_TTypes(0,    1,      2,      3,       4,                6,              8,              10,      11,       12,      13,    14,    15)
#                        0       1       2       3        4         5       6      7        8       9       10       11        12       13     14     15
const _TTypeNames   = ("STOP", "VOID", "BOOL", "BYTE", "DOUBLE",   "",    "I16",   "",     "I32",   "",     "I64", "STRING", "STRUCT", "MAP", "SET", "LIST")
const _TJTypes    =   (TSTOP,  TVOID,  TBOOL,  TBYTE,  TDOUBLE,  Nothing,  TI16, Nothing,  TI32,  Nothing,  TI64,  TSTRING,  TSTRUCT,  TMAP,  TSET,  TLIST)

#thrift_type_name(typ::Integer) = _TTypeNames[typ+1]

julia_type(typ::Integer) = _TJTypes[typ+1]
function julia_type(typ::Integer, narrow_typ)
    wide_typ = julia_type(typ)
    (narrow_typ <: wide_typ) && (return narrow_typ)
    error("Can not resolve type. $narrow_typ is not a subtype of $wide_typ")
end

thrift_type(::Type{TSTOP})                = Int32(0)
thrift_type(::Type{TVOID})                = Int32(1)
thrift_type(::Type{TBOOL})                = Int32(2)
thrift_type(::Type{TBYTE})                = Int32(3)
thrift_type(::Type{TDOUBLE})              = Int32(4)
thrift_type(::Type{TI16})                 = Int32(6)
thrift_type(::Type{TI32})                 = Int32(8)
thrift_type(::Type{TI64})                 = Int32(10)
thrift_type(::Type{TSTRING})              = Int32(11)
thrift_type(::Type{TUTF8})                = Int32(11)
thrift_type(::Type{TBINARY})              = Int32(11)
thrift_type(::Type{T}) where {T<:AbstractString} = Int32(11)
thrift_type(::Type{T}) where {T<:Any}            = Int32(12)
thrift_type(::Type{T}) where {T<:Dict}           = Int32(13)
thrift_type(::Type{T}) where {T<:Set}            = Int32(14)
thrift_type(::Type{T}) where {T<:Array}          = Int32(15)

const _container_type_ids   = (TType.STRUCT, TType.MAP, TType.SET, TType.LIST)
const _container_types      = (TSTRUCT, TMAP, TSET, TLIST)
const _plain_type_ids       = (TType.BOOL, TType.BYTE, TType.DOUBLE, TType.I16, TType.I32, TType.I64, TType.STRING)
const _plain_types          = (TBOOL, TBYTE, TDOUBLE, TI16, TI32, TI64, TBINARY, TUTF8)
iscontainer(typ::T)         where {T <: Integer}    = (Int32(typ) in _container_type_ids)
iscontainer(typ::Type{T})   where {T}               = iscontainer(thrift_type(typ))
isplain(typ::T)             where {T <: Integer}    = (Int32(typ) in _plain_type_ids)
isplain(typ::Type{T})       where {T}               = isplain(thrift_type(typ))

##
# base processor method
abstract type TProcessor end
process(tp::TProcessor) = nothing


##
# base transport types
abstract type TTransport end
abstract type TServerTransport <: TTransport end

##
# base server type
abstract type TServer end

##
# base protocol types
abstract type TProtocol end

##
# base protocol read and write methods
#instantiate(t::Type) = (t.abstract) ? error("can not instantiate abstract type $t") : ccall(:jl_new_struct_uninit, Any, (Any,Any...), t)
for _typ in _plain_types
    @eval begin
        write(p::TProtocol, val::$(_typ)) = 0
        read(p::TProtocol, ::Type{$(_typ)}) = nothing
        skip(p::TProtocol, ::Type{$(_typ)}) = read(p, $(_typ))
    end
end

writeMessageBegin(p::TProtocol, name::AbstractString, mtype::Int32, seqid::Integer)     = nothing
writeMessageEnd(p::TProtocol)                                                           = nothing
writeStructBegin(p::TProtocol, name::AbstractString)                                    = nothing
writeStructEnd(p::TProtocol)                                                            = nothing
writeFieldBegin(p::TProtocol, name::AbstractString, ttype::Int32, fid::Integer)         = nothing
writeFieldEnd(p::TProtocol)                                                             = nothing
writeFieldStop(p::TProtocol)                                                            = nothing
writeMapBegin(p::TProtocol, ktype::Int32, vtype::Int32, size::Integer)                  = nothing
writeMapEnd(p::TProtocol)                                                               = nothing
writeListBegin(p::TProtocol, etype::Int32, size::Integer)                               = nothing
writeListEnd(p::TProtocol)                                                              = nothing
writeSetBegin(p::TProtocol, etype::Int32, size::Integer)                                = nothing
writeSetEnd(p::TProtocol)                                                               = nothing
writeBool(p::TProtocol, val)                                                            = write(p, convert(TBOOL, val))
writeByte(p::TProtocol, val)                                                            = write(p, convert(TBYTE, val))
writeI16(p::TProtocol, val)                                                             = write(p, convert(TI16, val))
writeI32(p::TProtocol, val)                                                             = write(p, convert(TI32, val))
writeI64(p::TProtocol, val)                                                             = write(p, convert(TI64, val))
writeDouble(p::TProtocol, val)                                                          = write(p, convert(TDOUBLE, val))
writeString(p::TProtocol, val)                                                          = write(p, String(val))
writeBinary(p::TProtocol, val)                                                          = write(p, convert(TBINARY, val))

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
readString(p::TProtocol)           = read(p, TUTF8)
readBinary(p::TProtocol)           = read(p, TBINARY)

skip(p::TProtocol, ::Type{T}) where {T<:TSTRUCT} = skip_container(p, T)
function skip_container(p::TProtocol, ::Type{T}) where T<:TSTRUCT
    @debug("skip TSTRUCT")
    name = readStructBegin(p)
    while true
        (name, ttype, id) = readFieldBegin(p)
        (ttype == TType.STOP) && break
        if iscontainer(ttyp)
            skip_container(p, julia_type(ttype))
        else
            skip(p, julia_type(ttype))
        end
        readFieldEnd(p)
    end
    readStructEnd(p)
    return
end

read(p::TProtocol, ::Type{T}) where {T<:TSTRUCT} = read(p, T())
read_container(p::TProtocol, ::Type{T}) where {T<:TSTRUCT} = read_container(p, T())
read(p::TProtocol, val::T) where {T<:TSTRUCT} = read_container(p, val)
function read_container(p::TProtocol, val::T) where T<:TSTRUCT
    @debug("read TSTRUCT", T)
    readStructBegin(p)

    m = meta(T)
    @debug("struct meta", meta=m)
    clear(val)
    while true
        (name, ttyp, id) = readFieldBegin(p)
        (ttyp == TType.STOP) && break

        attribs = m.numdict[Int(id)]
        jtyp = julia_type(attribs)
        fldname = attribs.fld
        if iscontainer(ttyp)
            if isdefined(val, fldname)
                @debug("reading into already defined container field", jtyp, fldname)
                read_container(p, getfield(val, fldname))
            else
                @debug("setting into container field", jtyp, fldname)
                setproperty!(val, fldname, read_container(p, jtyp))
            end
        else
            @debug("setting field", jtyp, fldname)
            setproperty!(val, fldname, read(p, jtyp))
        end
        readFieldEnd(p)
    end
    readStructEnd(p)

    # populate remaining with any defaults
    setdefaultproperties!(val)
end

function setdefaultproperties!(val::T) where T<:TSTRUCT
    m = meta(T)
    for attrib in m.ordered
        fldname = attrib.fld
        if !hasproperty(val, fldname) && !isempty(attrib.default)
            default = attrib.default[1]
            setproperty!(val, fldname, deepcopy(default))
        end
    end
    val
end

write(p::TProtocol, val::T) where {T<:TSTRUCT} = write_container(p, val)
function write_container(p::TProtocol, val::T) where T<:TSTRUCT
    m = meta(T)
    @debug("write TSTRUCT", T, meta=m)
    writeStructBegin(p, string(T))

    for attrib in m.ordered
        if !hasproperty(val, attrib.fld)
            m.symdict[attrib.fld].required && error("required field $(attrib.fld) not populated")
            continue
        end
        writeFieldBegin(p, string(attrib.fld), attrib.ttyp, attrib.fldnum)
        fld = getproperty(val, attrib.fld)
        if (attrib.ttyp == TType.STRING) && isa(fld, Vector{UInt8})
            write(p, fld, true)
        elseif attrib.ttyp == TType.BOOL
            writeBool(p, fld)
        else
            write(p, fld)
        end
        writeFieldEnd(p)
    end
    writeFieldStop(p)
    writeStructEnd(p)
    nothing
end

skip(p::TProtocol, ::Type{T}) where {T<:TMAP} = skip_container(p, T)
function skip_container(p::TProtocol, ::Type{T}) where T<:TMAP
    @debug("skip TMAP", T)
    (ktype, vtype, size) = readMapBegin(p)
    if size > 0
        jktype = julia_type(ktype)
        jvtype = julia_type(vtype)
        for i in 1:size
            skip(p, jktype)
            skip(p, jvtype)
        end
    end
    readMapEnd(p)
    return
end

read(p::TProtocol, ::Type{T}) where {T<:TMAP} = read(p, T())
read(p::TProtocol, val::T) where {T<:TMAP} = read_container(p, val)
function read_container(p::TProtocol, val::T) where T<:TMAP
    @debug("read TMAP", T)
    (ktype, vtype, size) = readMapBegin(p)
    if size > 0
        # types are valid only when size is non zero
        (_ktype, _vtype) = fieldtypes(eltype(val))
        jktype = julia_type(ktype, _ktype)
        jvtype = julia_type(vtype, _vtype)
        for i in 1:size
            k = read(p, jktype)
            v = read(p, jvtype)
            val[k] = v
        end
    end
    readMapEnd(p)
    val
end

write(p::TProtocol, val::TMAP) = write_container(p, val)
function write_container(p::TProtocol, val::TMAP)
    @debug("write TMAP", valtype=typeof(val), size=length(val))
    (ktype,vtype) = fieldtypes(eltype(val))
    writeMapBegin(p, thrift_type(ktype), thrift_type(vtype), length(val))
    for (k,v) in val
        @debug("write TMAP key")
        if ktype === Vector{UInt8}
            write(p, k, true)
        else
            write(p, k)
        end
        @debug("write TMAP value")
        if vtype === Vector{UInt8}
            write(p, v, true)
        else
            write(p, v)
        end
    end
    writeMapEnd(p)
end

skip(p::TProtocol, ::Type{T}) where {T<:TSET} = skip_container(p, T)
function skip_container(p::TProtocol, ::Type{T}) where T<:TSET
    @debug("skip TSET", T)
    (etype, size) = readSetBegin(p)
    if size > 0
        jetype = julia_type(etype)
        for i in 1:size
            skip(p, jetype)
        end
    end
    readSetEnd(p)
end

read(p::TProtocol, ::Type{T}) where {T<:TSET} = read(p, T())
read(p::TProtocol, val::T) where {T<:TSET} = read_container(p, val)
function read_container(p::TProtocol, val::T) where T<:TSET
    @debug("read TSET", T)
    (etype, size) = readSetBegin(p)
    if size > 0
        jetype = julia_type(etype, eltype(val))
        for i in 1:size
            push!(val, read(p, jetype))
        end
    end
    readSetEnd(p)
    val
end

write(p::TProtocol, val::TSET) = write_container(p, val)
function write_container(p::TProtocol, val::TSET)
    @debug("write TSET", valtype=typeof(val), size=length(val))
    jetype = eltype(val)
    tetype = thrift_type(jetype)
    writeSetBegin(p, tetype, length(val))

    if iscontainer(tetype)
        for v in val
            write(p, jetype, v)
        end
    else
        for v in val
            if jetype === Vector{UInt8}
                write(p, v, true)
            else
                write(p, v)
            end
        end
    end
    writeSetEnd(p)
end

skip(p::TProtocol, ::Type{T}) where {T<:TLIST} = skip_container(p, T)
function skip_container(p::TProtocol, ::Type{T}) where T<:TLIST
    @debug("skip TLIST", T)
    (etype, size) = readListBegin(p)
    if size > 0
        jetype = julia_type(etype)
        for i in 1:size
            skip(p, jetype)
        end
    end
    readListEnd(p)
end

read(p::TProtocol, ::Type{T}) where {T<:TLIST} = read(p, T())
read(p::TProtocol, val::T) where {T<:TLIST} = read_container(p, val)
function read_container(p::TProtocol, val::T) where T<:TLIST
    @debug("read TLIST", T)
    (etype, size) = readListBegin(p)
    if size > 0
        jetype = julia_type(etype, eltype(val))
        for i in 1:size
            push!(val, read(p, jetype))
        end
    end
    readListEnd(p)
    val
end

write(p::TProtocol, val::TLIST) = write_container(p, val)
function write_container(p::TProtocol, val::TLIST)
    @debug("write TLIST", valtype=typeof(val), size=length(val))
    etype = eltype(val)
    writeListBegin(p, thrift_type(etype), length(val))
    # TODO: need meta to convert type correctly
    for v in val
        if etype === Vector{UInt8}
            write(p, v, true)
        else
            write(p, v)
        end
    end
    writeListEnd(p)
    nothing
end


##
# Thrift Structure Metadata

mutable struct ThriftMetaAttribs
    fldnum::Int                     # the field number in the structure
    fld::Symbol
    ttyp::Int32                     # thrift type
    jtype::Type                     # Julia type
    required::Bool                  # required or optional
    default::Vector                 # the default value, empty array if none is specified, first element is used if something is specified
    elmeta::Vector                  # the ThriftMeta of a struct or element/key-value types if this is a list, set or map
end

mutable struct ThriftMeta
    jtype::Type
    symdict::Dict{Symbol,ThriftMetaAttribs}
    numdict::Dict{Int,ThriftMetaAttribs}
    ordered::Vector{ThriftMetaAttribs}

    ThriftMeta(jtype::Type, ordered::Vector{ThriftMetaAttribs}) = _setmeta(new(), jtype, ordered)
end

function _setmeta(meta::ThriftMeta, jtype::Type, ordered::Vector{ThriftMetaAttribs})
    symdict = Dict{Symbol,ThriftMetaAttribs}()
    numdict = Dict{Int,ThriftMetaAttribs}()
    for attrib in ordered
        symdict[attrib.fld] = numdict[attrib.fldnum] = attrib
    end
    meta.jtype = jtype
    meta.symdict = symdict
    meta.numdict = numdict
    meta.ordered = ordered
    meta
end

julia_type(fattr::ThriftMetaAttribs) = fattr.jtype

meta(typ::Type) = meta(typ, Symbol[], Type[], Symbol[], Int[], Dict{Symbol,Any}())
function meta(typ::Type, names::Vector{Symbol}, types::Vector{Type}, optional::Vector{Symbol}, numbers::Vector{Int}, defaults::Dict{Symbol,Any})
    m = ThriftMeta(typ, ThriftMetaAttribs[])

    attribs = ThriftMetaAttribs[]
    for fldidx in 1:length(names)
        fldtyp = types[fldidx]
        fldttyp = thrift_type(fldtyp)
        fldname = names[fldidx]
        fldnum = Int(isempty(numbers) ? fldidx : numbers[fldidx])
        fldrequired = !(fldname in optional)

        elmeta = ThriftMeta[]
        if fldttyp == TType.STRUCT
            push!(elmeta, meta(fldtyp))
        elseif fldttyp == TType.LIST
            push!(elmeta, meta(fldtyp.parameters[1]))
        elseif fldttyp == TType.SET
            push!(elmeta, meta(fldtyp.parameters[1]))
        elseif fldttyp == TType.MAP
            push!(elmeta, meta(fldtyp.parameters[1]))   # key
            push!(elmeta, meta(fldtyp.parameters[2]))   # value
        end

        default = haskey(defaults, fldname) ? Any[defaults[fldname]] : []

        push!(attribs, ThriftMetaAttribs(fldnum, fldname, fldttyp, fldtyp, fldrequired, default, elmeta))
    end
    _setmeta(m, typ, attribs)
    m
end

function show(io::IO, m::ThriftMeta)
    println(io, "ThriftMeta for $(m.jtype)")
    println(io, m.ordered)
end

@deprecate fillunset(obj) clear(obj)
@deprecate isfilled(obj, fld) hasproperty(obj, fld)
function isfilled(obj)
    fill = keys(obj.values)
    flds = obj.meta.ordered
    for fld in flds
        if fld.required
            (fld.fld in fill) || (return false)
            !isempty(fld.elmeta) && !isfilled(getproperty(obj, fld.fld)) && (return false)
        end
    end
    true
end
function isfilled(vec::Vector{T}) where T<:TMsg
    isempty(vec) || all(isfilled.(vec))
end

##
# utility methods
function copy!(to::T, from::T) where T<:TMsg
    clear(to)
    for name in propertynames(from)
        if hasproperty(from, name)
            setproperty!(to, name, getproperty(from, name))
        end
    end
    nothing
end

isinitialized(obj) = isfilled(obj)

@deprecate set_field!(obj, fld, val) setproperty!(obj, fld, val)
@deprecate get_field(obj, fld) getproperty(obj, fld)
@deprecate has_field(obj, fld) hasproperty(obj, fld)

propertynames(obj::TMsg) = collect(keys(obj.meta.symdict))
hasproperty(obj::TMsg, fld::Symbol) = haskey(obj.values, fld)
function setproperty!(obj::TMsg, fld::Symbol, val)
    symdict = obj.meta.symdict
    if fld in keys(symdict)
        fldtype = symdict[fld].jtype
        obj.values[fld] = isa(val, fldtype) ? val : convert(fldtype, val)
    else
        setfield!(obj, fld, val)
    end
end

function clear(obj::TMsg)
    empty!(obj.values)
    nothing
end

function clear(obj::TMsg, fld::Symbol)
    delete!(obj.values, fld)
    nothing
end

function thriftbuild(::Type{T}, nv::Dict{Symbol}=Dict{Symbol,Any}()) where T
    Base.depwarn("thriftbuild is deprecated; use constructor instead", :thriftbuild)
    T(; nv...)
end

function enumstr(enumname, t::Int32)
    T = typeof(enumname)
    for name in fieldnames(T)
        (getfield(enumname, name) == t) && (return string(name))
    end
    error("Invalid enum value $t for $T)")
end


##
# Exception types
"""
Exception that must be thrown by application code on any unexpected error.
"""
mutable struct TException <: TMsg
    meta::ThriftMeta
    values::Dict{Symbol,Any}

    function TException(; kwargs...)
        obj = new(__meta__TException, Dict{Symbol,Any}())
        values = obj.values
        symdict = obj.meta.symdict
        for nv in kwargs
            fldname, fldval = nv
            fldtype = symdict[fldname].jtype
            (fldname in keys(symdict)) || error(string(typeof(obj), " has no field with name ", fldname))
            values[fldname] = isa(fldval, fldtype) ? fldval : convert(fldtype, fldval)
        end
        Thrift.setdefaultproperties!(obj)
        obj
    end
end

const __meta__TException = meta(TException,
    Symbol[:message],
    Type[String],
    Symbol[],
    Int[],
    Dict{Symbol,Any}()
)

function Base.getproperty(obj::TException, name::Symbol)
    if name === :message
        return (obj.values[name])::String
    else
        getfield(obj, name)
    end
end

meta(::Type{TException}) = __meta__TException

struct _enum_TApplicationExceptionTypes
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

const ApplicationExceptionType = _enum_TApplicationExceptionTypes(Int32(0), Int32(1), Int32(2), Int32(3), Int32(4), Int32(5), Int32(6), Int32(7), Int32(8), Int32(9), Int32(10))
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

"""
Exception thrown by Thrift.jl internals on any unexpected error.
"""
mutable struct TApplicationException <: TMsg
    meta::ThriftMeta
    values::Dict{Symbol,Any}

    function TApplicationException(; kwargs...)
        obj = new(__meta__TApplicationException, Dict{Symbol,Any}())
        values = obj.values
        symdict = obj.meta.symdict
        for nv in kwargs
            fldname, fldval = nv
            fldtype = symdict[fldname].jtype
            (fldname in keys(symdict)) || error(string(typeof(obj), " has no field with name ", fldname))
            values[fldname] = isa(fldval, fldtype) ? fldval : convert(fldtype, fldval)
        end
        Thrift.setdefaultproperties!(obj)
        obj
    end
end

const __meta__TApplicationException = meta(TApplicationException,
    Symbol[:typ, :message],
    Type[Int32, TUTF8],
    Symbol[],
    Int[],
    Dict{Symbol,Any}(
        :typ => ApplicationExceptionType.UNKNOWN,
        :message => ""
    )
)

function Base.getproperty(obj::TApplicationException, name::Symbol)
    if name === :typ
        return (obj.values[name])::Int32
    elseif name === :message
        return (obj.values[name])::TUTF8
    else
        getfield(obj, name)
    end
end

meta(::Type{TApplicationException}) = __meta__TApplicationException


##
# Message types
struct _enum_TMessageType
    CALL::Int32
    REPLY::Int32
    EXCEPTION::Int32
    ONEWAY::Int32
end

const MessageType = _enum_TMessageType(Int32(1), Int32(2), Int32(3), Int32(4))
