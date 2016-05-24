module MemTransportTests

using Thrift
using Compat
using Base.Test

function testmemtransport()
    println("\nTesting memory transport...")
    t = TMemoryTransport()
    p = TCompactProtocol(t)

    s1 = "Hello World"
    write(p, s1)
    s2 = read(p, typeof(s1))
    @test s2 == s1
    println("passed.")
end

testmemtransport()

end
