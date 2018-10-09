module FileTransportTests

using Thrift
using Compat
using Compat.Test

function testfiletransport()
    println("\nTesting file transport...")

    fname = tempname()
    s1 = "Hello World"
    open(fname, "w") do f
        t = TFileTransport(f)
        p = TCompactProtocol(t)

        @test open(t) === nothing
        @test close(t) === nothing
        @test flush(t) === nothing
        @test isa(Thrift.rawio(t), IO)
        @test isopen(t)

        for i in 1:5
            write(p, s1)
        end
    end

    open(fname, "r") do f
        t = TFileTransport(f)
        p = TCompactProtocol(t)
        for i in 1:5
            s2 = read(p, typeof(s1))
            @test s2 == s1
        end
        println("passed.")
    end
    rm(fname)
end

testfiletransport()

end
