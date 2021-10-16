module ThriftUtilsTests

using Thrift
using Test
import Thrift: meta
using Base.Threads

struct _enum_TestEnum
    BOOLEAN::Int32
    INT32::Int32
    INT64::Int32
    INT96::Int32
    FLOAT::Int32
    DOUBLE::Int32
    BYTE_ARRAY::Int32
    FIXED_LEN_BYTE_ARRAY::Int32
end
const TestEnum = _enum_TestEnum(Int32(0), Int32(1), Int32(2), Int32(3), Int32(4), Int32(5), Int32(6), Int32(7))

function test_enum()
    @testset "enum" begin
        @test enumstr(TestEnum, TestEnum.BOOLEAN) == "BOOLEAN"
        @test_throws ErrorException enumstr(TestEnum, Int32(11))
    end
end

function test_container_check()
    @testset "iscontainer/isplain" begin
        for T in (Bool, UInt8, Float64, Int16, Int32, Int64, Vector{UInt8}, String)
            @test Thrift.isplain(T)
            @test !Thrift.iscontainer(T)
        end
        for T in (Dict, Set, Any)
            @test !Thrift.isplain(T)
            @test Thrift.iscontainer(T)
        end
    end
end

mutable struct TestMetaAllTypes <: Thrift.TMsg
    meta::ThriftMeta
    values::Dict{Symbol,Any}

    function TestMetaAllTypes(; kwargs...)
        obj = new(__meta__TestMetaAllTypes, Dict{Symbol,Any}())
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
end # mutable struct TestMetaAllTypes

const __meta__TestMetaAllTypes = meta(TestMetaAllTypes,
    Symbol[:bool_val,:byte_val,:i16_val,:i32_val,:i64_val,:double_val,:string_val],
    Type[Bool, UInt8, Int16, Int32, Int64, Float64, String],
    Symbol[],
    Int[],
    Dict{Symbol,Any}()
)

function Base.getproperty(obj::TestMetaAllTypes, name::Symbol)
    if name === :bool_val
        return (obj.values[name])::Bool
    elseif name === :byte_val
        return (obj.values[name])::UInt8
    elseif name === :i16_val
        return (obj.values[name])::Int16
    elseif name === :i32_val
        return (obj.values[name])::Int32
    elseif name === :i64_val
        return (obj.values[name])::Int64
    elseif name === :double_val
        return (obj.values[name])::Float64
    elseif name === :string_val
        return (obj.values[name])::String
    else
        getfield(obj, name)
    end
end

meta(::Type{TestMetaAllTypes}) = __meta__TestMetaAllTypes


mutable struct AllTypesDefault <: Thrift.TMsg
    meta::ThriftMeta
    values::Dict{Symbol,Any}

    function AllTypesDefault(; kwargs...)
        obj = new(__meta__AllTypesDefault, Dict{Symbol,Any}())
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
end # mutable struct AllTypesDefault

const __meta__AllTypesDefault = meta(AllTypesDefault,
  Symbol[:bool_val,:byte_val,:i16_val,:i32_val,:i64_val,:double_val,:string_val,:map_val,:list_val,:set_val],
  Type[Bool,UInt8,Int16,Int32,Int64,Float64,String,Dict{Int32,Int16},Vector{Int16},Set{UInt8}],
  Symbol[:bool_val,:byte_val,:i16_val,:i32_val,:i64_val,:double_val,:string_val,:map_val,:list_val,:set_val],
  Int[],
  Dict{Symbol,Any}(:bool_val => true, :byte_val => UInt8(1), :i16_val => Int16(10), :i32_val => Int32(20), :i64_val => Int64(30), :double_val => Float64(10.1), :string_val => "hello world", :map_val => Dict(Int32(1) => Int16(10), Int32(2) => Int16(20)), :list_val => Int16[1, 2, 3], :set_val => union!(Set{UInt8}(), UInt8[3, 4, 5]))
)

function Base.getproperty(obj::AllTypesDefault, name::Symbol)
    if name === :bool_val
        return (obj.values[name])::Bool
    elseif name === :byte_val
        return (obj.values[name])::UInt8
    elseif name === :i16_val
        return (obj.values[name])::Int16
    elseif name === :i32_val
        return (obj.values[name])::Int32
    elseif name === :i64_val
        return (obj.values[name])::Int64
    elseif name === :double_val
        return (obj.values[name])::Float64
    elseif name === :string_val
        return (obj.values[name])::String
    elseif name === :map_val
        return (obj.values[name])::Dict{Int32,Int16}
    elseif name === :list_val
        return (obj.values[name])::Vector{Int16}
    elseif name === :set_val
        return (obj.values[name])::Set{UInt8}
    else
        getfield(obj, name)
    end
end

meta(::Type{AllTypesDefault}) = __meta__AllTypesDefault

function test_meta()
    @testset "test metadata" begin
        @test !Thrift.isplain(TestMetaAllTypes)
        @test Thrift.iscontainer(TestMetaAllTypes)

        types = TestMetaAllTypes()
        @test !isfilled(types)
        @test !hasproperty(types, :bool_val)

        types.bool_val = true
        @test hasproperty(types, :bool_val)
        @test !isfilled(types)

        types.byte_val = 1
        types.i16_val = 1
        types.i32_val = 1
        types.i64_val = 1
        types.double_val = 1.1
        types.string_val = "1"

        @test isfilled(types)
        @test isinitialized(types)

        types2 = TestMetaAllTypes()
        @test !isfilled(types2)
        copy!(types2, types)
        @test isfilled(types2)

        types3 = AllTypesDefault()
        @test isfilled(types3)
    end

    nothing
end

function test_parallel_readwrite()
    types = TestMetaAllTypes()
    types.bool_val = true
    types.byte_val = 1
    types.i16_val = 1
    types.i32_val = 1
    types.i64_val = 1
    types.double_val = 1.1
    types.string_val = "1"

    iob = IOBuffer()
    transport = TFileTransport(iob)
    Thrift.write(Thrift.TCompactProtocol(transport), types)
    transport = TFileTransport(IOBuffer(take!(iob)))
    types_read = Thrift.read(Thrift.TCompactProtocol(transport), TestMetaAllTypes)

    for name in propertynames(types)
        @test getproperty(types_read, name) == getproperty(types, name)
    end
end

function test_zigzag()
    testcases = [
        0 => (nbytes=1, encval=0),
        -1 => (nbytes=1, encval=1),
        1 => (nbytes=1, encval=2),
        -2 => (nbytes=1, encval=3),
        2147483647 => (nbytes=5, encval=4294967294),
        -2147483648 => (nbytes=5, encval=4294967295)
    ]

    for T in (Int64, Int32)
        iob = PipeBuffer()
        for kv in testcases
            @test Thrift._write_zigzag(iob, T(kv[1])) == kv[2].nbytes
        end
        for kv in testcases
            read_val = Thrift._read_zigzag(iob, T)
            @test read_val === T(kv[1])
        end
    end
end

@testset "utility functions" begin
    test_enum()
    test_container_check()
    test_meta()
    test_zigzag()
end

@testset "parallel read write" begin
    Threads.@threads for idx in 1:10
        test_parallel_readwrite()
    end

    @sync begin
        for idx in 1:10
            @async test_parallel_readwrite()
        end
    end
end

end
