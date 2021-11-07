using Thrift
using Test

@testset "HeaderTransport" begin

    @testset "Simple case" begin
        memory_transport = TMemoryTransport()
        header_transport = THeaderTransport(transport=memory_transport)

        # Check initial state
        @test bytesavailable(header_transport.rbuf) == 0
        @test bytesavailable(header_transport.wbuf) == 0

        # Write some bytes
        bytes = rand(UInt8(1):UInt8(4), 100)
        write(header_transport, bytes)
        @test bytesavailable(header_transport.wbuf) == length(bytes)

        # Flushing the transport should put data in to the memory transport
        flush(header_transport)
        @test bytesavailable(header_transport.wbuf) == 0

        # Confirm that read buffer is still empty
        @test bytesavailable(header_transport.rbuf) == 0

        # Now, read a frame, which pulls data from the memory transport
        Thrift.read_frame!(header_transport)
        @test bytesavailable(header_transport.rbuf) > 0

        # Check default read header
        @test length(header_transport.read_headers) > 0
        @test header_transport.read_headers["client_metadata"] ==
            "{\"agent\":\"Julia THeaderTransport\"}"

        # Verify that data is read
        @test bytesavailable(header_transport.rbuf) == length(bytes)
        @test read(header_transport.rbuf) == bytes
    end

    @testset "Transformation" begin
        memory_transport = TMemoryTransport()
        header_transport = THeaderTransport(
            transport=memory_transport,
            write_transforms=Thrift.TransformType.ZLIB
        )
        bytes = rand(UInt8(1):UInt8(4), 100)
        write(header_transport, bytes)
        flush(header_transport)  # transformation happens now

        Thrift.read_frame!(header_transport)
        @test header_transport.read_headers["client_metadata"] ==
            "{\"agent\":\"Julia THeaderTransport\"}"
        @test read(header_transport.rbuf) == bytes
    end
end
