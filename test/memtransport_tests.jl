module MemTransportTests

using Thrift
using Test

function testmemtransport()
    @testset "memory transport" begin
        t = TMemoryTransport()
        p = TCompactProtocol(t)

        @test open(t) === nothing
        @test close(t) === nothing
        @test flush(t) === nothing
        @test isa(Thrift.rawio(t), IOBuffer)
        @test isopen(t)

        s1 = "Hello World"
        write(p, s1)
        s2 = read(p, typeof(s1))
        @test s2 == s1

        t = TMemoryTransport()
        p = TCompactProtocol(t)
        write(p, s1)
        t = TMemoryTransport(take!(t.buff))
        p = TCompactProtocol(t)
        s2 = read(p, typeof(s1))
        @test s2 == s1
    end
end

testmemtransport()

end # module MemTransportTests
