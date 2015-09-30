##
# Base Thrift type system
type TSTOP end
typealias TVOID     Void
typealias TBOOL     Bool
typealias TBYTE     UInt8
typealias TI08      UInt8
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
    function _enum_TTypes(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17)
        new(Int32(p1), Int32(p2), Int32(p3), Int32(p4), Int32(p5), Int32(p6), Int32(p7), Int32(p8), Int32(p9), Int32(p10), Int32(p11), Int32(p12), Int32(p13), Int32(p14), Int32(p15), Int32(p16), Int32(p17))
    end
end

const TType = _enum_TTypes(0,    1,      2,      3,3,     4,              6,             8,            10,    11,11,     12,      13,    14,     15,      16,    17)
#                        0       1       2       3        4       5       6     7        8     9       10     11         12       13     14      15       16     17
const _TTypeNames   = ["STOP", "VOID", "BOOL", "BYTE", "DOUBLE", "",    "I16", "",     "I32", "",     "I64", "STRING", "STRUCT", "MAP", "SET", "LIST", "UTF8", "UTF16"]
const _TJTypes    =   [TSTOP,  TVOID,  TBOOL,  TBYTE,  TDOUBLE, Void, TI16, Void, TI32, Void, TI64,  TSTRING,  TSTRUCT,  TMAP,  TSET,  TLIST,  TUTF8,  TUTF16]

thrift_type_name(typ::Integer) = _TTypeNames[typ+1]

julia_type(typ::Integer) = _TJTypes[typ+1]

thrift_type(::Type{TSTOP})          = Int32(0)
thrift_type(::Type{TVOID})          = Int32(1)
thrift_type(::Type{TBOOL})          = Int32(2)
thrift_type(::Type{TBYTE})          = Int32(3)
thrift_type(::Type{TDOUBLE})        = Int32(4)
thrift_type(::Type{TI16})           = Int32(6)
thrift_type(::Type{TI32})           = Int32(8)
thrift_type(::Type{TI64})           = Int32(10)
thrift_type(::Type{TSTRING})        = Int32(11)
thrift_type{T<:Any}(::Type{T})      = Int32(12)
thrift_type{T<:Dict}(::Type{T})     = Int32(13)
thrift_type{T<:Set}(::Type{T})      = Int32(14)
thrift_type{T<:Array}(::Type{T})    = Int32(15)
thrift_type(::Type{TUTF8})          = Int32(16)
thrift_type(::Type{TUTF16})         = Int32(17)
thrift_type(::Type{AbstractString}) = Int32(11)

const _container_type_ids = [TType.STRUCT, TType.MAP, TType.SET, TType.LIST]
const _container_types    = [TSTRUCT, TMAP, TSET, TLIST]
iscontainer(typ::Integer)   = (Int32(typ) in _container_type_ids)
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
writeString(p::TProtocol, val)                                                          = write(p, bytestring(val))

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
readString(p::TProtocol)           = read(p, UTF8String)


function skip{T<:TSTRUCT}(p::TProtocol, ::Type{T})
    #logmsg("skip TSTRUCT")
    name = readStructBegin(p)
    while true
        (name, ttype, id) = readFieldBegin(p)
        (ttype == TType.STOP) && break
        skip(p, julia_type(ttype))
        readFieldEnd(p)
    end
    readStructEnd(p)
    return
end

function read{T<:TSTRUCT}(p::TProtocol, t::Type{T}, val=nothing)
    (t == Any) && (val != nothing) && (t = typeof(val))
    name = readStructBegin(p)
    (t == Any) && (name != nothing) && (t = eval(symbol(name)))

    (t == Any) && error("can not read unknown struct type")
    if val == nothing 
        val = instantiate(t)
    else
        !issubtype(typeof(val), t) && error("can not read $t into $(typeof(val))")
    end

    #logmsg("read TSTRUCT $t")

    m = meta(t)
    #logmsg("struct meta: $m")
    fillunset(val)
    while true
        (name, ttyp, id) = readFieldBegin(p)
        (ttyp == TType.STOP) && break

        attribs = m.numdict[Int(id)]
        (ttyp != attribs.ttyp) && !((attribs.ttyp == TType.UTF8) && (ttyp == TType.STRING)) && error("can not read field of type $ttyp into type $(attribs.ttyp)")
        (nothing != name) && (symbol(name) != attribs.fld) && error("field names do not match. got $(name), have $(attribs.fld)")

        jtyp = julia_type(attribs)
        fldname = attribs.fld
        if iscontainer(ttyp)
            if !isdefined(val, fldname)
                setfield!(val, fldname, read(p, jtyp))
            else
                read(p, jtyp, getfield(val, fldname))
            end
        else
            setfield!(val, fldname, read(p, jtyp))
        end
        fillset(val, fldname)
        readFieldEnd(p)
    end
    readStructEnd(p)

    # populate defaults
    for attrib in m.ordered
        fldname = attrib.fld
        if !isfilled(val, fldname) && (length(attrib.default) > 0)
            default = attrib.default[1]
            setfield!(val, fldname, deepcopy(default))
            fillset(val, fldname)
        end
    end

    val
end

function write(p::TProtocol, val::TSTRUCT)
    t = typeof(val)
    m = meta(t)
    #logmsg("write TSTRUCT $t")
    #logmsg("struct meta: $m")
    writeStructBegin(p, string(t))

    for attrib in m.ordered
        if !isfilled(val, attrib.fld)
            m.symdict[attrib.fld].required && error("required field $(attrib.fld) not populated")
            continue
        end
        writeFieldBegin(p, string(attrib.fld), attrib.ttyp, attrib.fldnum)
        write(p, getfield(val, attrib.fld))
        writeFieldEnd(p)
    end
    writeFieldStop(p)
    writeStructEnd(p)
    nothing
end

function skip{T<:TMAP}(p::TProtocol, ::Type{T})
    #logmsg("skip TMAP")
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

function read{T<:TMAP}(p::TProtocol, ::Type{T}, val=nothing)
    (ktype, vtype, size) = readMapBegin(p)
    jktype = julia_type(ktype)
    jvtype = julia_type(vtype)

    #logmsg("read TMAP key: $jktype, val: $jvtype")

    if val == nothing
        val = Dict{jktype,jvtype}()
    else
        (_ktype, _vtype) = eltype(val).types
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
    (ktype,vtype) = eltype(val).types
    #logmsg("write TMAP key: $ktype, val: $vtype")
    writeMapBegin(p, thrift_type(ktype), thrift_type(vtype), length(val))
    for (k,v) in val
        write(p, k)
        write(p, v)
    end
    writeMapEnd(p)
end

function skip{T<:TSET}(p::TProtocol, ::Type{T})
    #logmsg("skip TSET")
    (etype, size) = readSetBegin(p)
    jetype = julia_type(etype)
    for i in 1:size
        skip(p, jetype)
    end
    readSetEnd(p)
end

function read{T<:TSET}(p::TProtocol, ::Type{T}, val=nothing)
    (etype, size) = readSetBegin(p)
    #logmsg("read TSET, etype: $etype, size: $size")
    jetype = julia_type(etype)
    if val == nothing
        val = Set{jetype}()
    else
        !issubtype(jetype, eltype(val)) && error("can not read $jetype into $(typeof(val))")
    end

    for i in 1:size
        push!(val, read(p, jetype))
    end
    readSetEnd(p)
    val
end

function write(p::TProtocol, val::TSET)
    jetype = eltype(val)
    tetype = thrift_type(jetype)
    #logmsg("write TSET, etype: $jetype, size: $(length(val))")
    writeSetBegin(p, tetype, length(val))

    if iscontainer(tetype)
        for v in val
            write(p, jetype, v)
        end
    else
        for v in val
            write(p, v)
        end
    end
    writeSetEnd(p)
end

function skip{T<:TLIST}(p::TProtocol, ::Type{T})
    #logmsg("skip TLIST")
    (etype, size) = readListBegin(p)
    jetype = julia_type(etype)
    for i in 1:size
        skip(p, jetype)
    end
    readListEnd(p)
end

function read{T<:TLIST}(p::TProtocol, ::Type{T}, val=nothing)
    (etype, size) = readListBegin(p)
    jetype = julia_type(etype)
    #logmsg("read TLIST, etype: $jetype, size: $size")
    if val == nothing
        val = Array(jetype,0)
    else
        !issubtype(eltype(val), jetype) && error("can not read $jetype into $(typeof(val))")
    end

    for i in 1:size
        push!(val, read(p, jetype))
    end
    readListEnd(p)
    val
end

function write(p::TProtocol, val::TLIST)
    #logmsg("write TLIST, etype: $(eltype(val)), size: $(length(val))")
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
    message::AbstractString
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
    
type TApplicationException <: Exception
    typ::Int32
    message::AbstractString

    TApplicationException(typ::Int32=ApplicationExceptionType.UNKNOWN, message::AbstractString="") = new(typ, isempty(message) ? _appex_msgs[typ+1] : message)
end



##
# Message types
type _enum_TMessageType
    CALL::Int32
    REPLY::Int32
    EXCEPTION::Int32
    ONEWAY::Int32
end 

const MessageType = _enum_TMessageType(Int32(1), Int32(2), Int32(3), Int32(4))



##
# Thrift Structure Metadata

type ThriftMetaAttribs
    fldnum::Int                     # the field number in the structure
    fld::Symbol
    ttyp::Int32                     # thrift type
    required::Bool                  # required or optional
    default::Array                  # the default value, empty array if none is specified, first element is used if something is specified
    elmeta::Array                   # the ThriftMeta of a struct or element/key-value types if this is a list, set or map
end

type ThriftMeta
    jtype::Type
    symdict::Dict{Symbol,ThriftMetaAttribs}
    numdict::Dict{Int,ThriftMetaAttribs}
    ordered::Array{ThriftMetaAttribs,1}

    ThriftMeta(jtype::Type, ordered::Array{ThriftMetaAttribs,1}) = _setmeta(new(), jtype, ordered)
end

function _setmeta(meta::ThriftMeta, jtype::Type, ordered::Array{ThriftMetaAttribs,1})
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

function julia_type(fattr::ThriftMetaAttribs)
    ttyp = fattr.ttyp
    !iscontainer(ttyp) && (return julia_type(ttyp))

    elmeta = fattr.elmeta
    if ttyp == TType.STRUCT
        return elmeta[1].jtype
    elseif ttyp == TType.LIST
        return Array{elmeta[1].jtype, 1}
    elseif ttyp == TType.SET
        return Set{elmeta[1].jtype}
    elseif ttyp == TType.MAP
        return Dict{elmeta[1].jtype, elmeta[2].jtype}
    end
    error("unknown type $ttyp in field attributes")
end


const _metacache = Dict{Type, ThriftMeta}()
const _fillcache = Dict{UInt, Array{Symbol,1}}()

meta(typ::Type) = meta(typ, Symbol[], Int[], Dict{Symbol,Any}())
function meta(typ::Type, optional::Array, numbers::Array, defaults::Dict, cache::Bool=true)
    d = Dict{Symbol,Any}()
    for (k,v) in defaults
        d[k] = v
    end
    meta(typ, convert(Array{Symbol,1}, optional), convert(Array{Int,1}, numbers), d, cache)
end
function meta(typ::Type, optional::Array{Symbol,1}, numbers::Array{Int,1}, defaults::Dict{Symbol,Any}, cache::Bool=true)
    haskey(_metacache, typ) && return _metacache[typ]

    m = ThriftMeta(typ, ThriftMetaAttribs[])
    cache ? (_metacache[typ] = m) : m

    attribs = ThriftMetaAttribs[]
    names = fieldnames(typ)
    types = typ.types
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

        push!(attribs, ThriftMetaAttribs(fldnum, fldname, fldttyp, fldrequired, default, elmeta))
    end
    _setmeta(m, typ, attribs)
    m
end

function show(io::IO, m::ThriftMeta)
    println(io, "ThriftMeta for $(m.jtype)")
    println(io, m.ordered)
end


fillunset(obj) = (empty!(filled(obj)); nothing)
function fillunset(obj, fld::Symbol)
    fill = filled(obj)
    idx = findfirst(fill, fld)
    (idx > 0) && splice!(fill, idx)
    nothing
end

function fillset(obj, fld::Symbol)
    fill = filled(obj)
    idx = findfirst(fill, fld)
    (idx > 0) && return
    push!(fill, fld)
    nothing
end

function filled(obj)
    oid = object_id(obj)
    haskey(_fillcache, oid) && return _fillcache[oid]

    fill = Symbol[]
    for fldname in fieldnames(typeof(obj))
        isdefined(obj, fldname) && push!(fill, fldname)
    end
    if !isimmutable(obj)
        _fillcache[oid] = fill
        finalizer(obj, obj->delete!(_fillcache, object_id(obj)))
    end
    fill
end

isfilled(obj, fld::Symbol) = (fld in filled(obj))
function isfilled(obj)
    fill = filled(obj)
    flds = meta(typeof(obj)).ordered
    for fld in flds
        if fld.required
            !(fld.fld in fill) && (return false)
            (fld.meta != nothing) && !isfilled(getfield(obj, fld.fld)) && (return false)
        end
    end
    true
end


##
# utility methods
# utility methods
function copy!(to::Any, from::Any)
    totype = typeof(to)
    fromtype = typeof(from)
    (totype != fromtype) && error("Can't copy a type $fromtype to $totype")
    fillunset(to)
    for name in fieldnames(totype)
        if isfilled(from, name)
            setfield!(to, name, getfield(from, name))
            fillset(to, name)
        end
    end
    nothing
end

isinitialized(obj::Any) = isfilled(obj)
set_field(obj::Any, fld::Symbol, val) = (setfield!(obj, fld, val); fillset(obj, fld); nothing)
get_field(obj::Any, fld::Symbol) = isfilled(obj, fld) ? getfield(obj, fld) : error("uninitialized field $fld")
clear = fillunset
has_field(obj::Any, fld::Symbol) = isfilled(obj, fld)

