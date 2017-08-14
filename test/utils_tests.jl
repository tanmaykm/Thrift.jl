module ThriftUtilsTests

using Thrift
using Base.Test

type _enum_TestEnum
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

println("Testing utils functions...")
test_enum()
test_container_check()
println("passed.")

end
