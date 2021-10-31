using Thrift
using Test

@testset "HeaderTransport" begin
    memory_transport = TMemoryTransport()
    header_transport = THeaderTransport(transport=memory_transport)

    @test bytesavailable(header_transport.wbuf) === 0

    write(header_transport, [0x01, 0x02])
    @test bytesavailable(header_transport.wbuf) === 2

    flush(header_transport)
    @test bytesavailable(header_transport.wbuf) === 0

    @show bytesavailable(memory_transport.buff)

    # fill rbuf for testing only
    # write(header_transport.rbuf, take!(memory_transport.buff))

    @show header_transport.rbuf
    @show Thrift.read_frame!(header_transport, 72 - 4)  # exclude LENGTH32
    @show header_transport.read_headers
end
