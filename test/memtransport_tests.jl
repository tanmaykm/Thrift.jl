using Thrift
using Base.Test

function testmemtransport()
    println("\nTesting memory transport...")
    t = TMemoryTransport()
    p = TCompactProtocol(t)

    s1 = "Hello World"
    write(p, s1)
    s2 = read(p, ASCIIString)
    @test s2 == s1
    println("Memory Transport tests passed.")
end

testmemtransport()
