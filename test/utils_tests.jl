module ThriftUtilsTests

using Thrift
using Test

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
    println("    enum...")
    @test enumstr(TestEnum, TestEnum.BOOLEAN) == "BOOLEAN"
    @test_throws ErrorException enumstr(TestEnum, Int32(11))
end

function test_container_check()
    println("    iscontainer/isplain...")
    for T in (Bool, UInt8, Float64, Int16, Int32, Int64, Vector{UInt8}, String)
        @test Thrift.isplain(T)
        @test !Thrift.iscontainer(T)
    end
    for T in (Dict, Set, Any)
        @test !Thrift.isplain(T)
        @test Thrift.iscontainer(T)
    end
end

mutable struct TestMetaAllTypes <: Thrift.TMsg
  bool_val::Bool
  byte_val::UInt8
  i16_val::Int16
  i32_val::Int32
  i64_val::Int64
  double_val::Float64
  string_val::String
  TestMetaAllTypes() = (o=new(); fillunset(o); o)
end # mutable struct AllTypes

function test_meta()
    @test !Thrift.isplain(TestMetaAllTypes)
    @test Thrift.iscontainer(TestMetaAllTypes)

    types = TestMetaAllTypes()
    @test !isfilled(types)
    @test !isfilled(types, :bool_val)

    set_field!(types, :bool_val, true)
    @test isfilled(types, :bool_val)
    @test !isfilled(types)

    set_field!(types, :byte_val,    UInt8(1))
    set_field!(types, :i16_val,     Int16(1))
    set_field!(types, :i32_val,     Int32(1))
    set_field!(types, :i64_val,     Int64(1))
    set_field!(types, :double_val,  1.1)
    set_field!(types, :string_val,  "1")
    @test isfilled(types)
    @test isinitialized(types)

    types2 = TestMetaAllTypes()
    @test !isfilled(types2)
    copy!(types2, types)
    @test isfilled(types2)

    nothing
end

println("Testing utils functions...")
test_enum()
test_container_check()
test_meta()
println("passed.")

end
