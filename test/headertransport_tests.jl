using Thrift
using Test

@testset "HeaderTransport" begin

    @testset "Write and read data" begin
        memory_transport = TMemoryTransport()
        header_transport = THeaderTransport(memory_transport)

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

        # Verify that data is read correctly
        @test bytesavailable(header_transport.rbuf) == length(bytes)
        @test read(header_transport.rbuf) == bytes
    end

    @testset "Apply transformation" begin
        memory_transport = TMemoryTransport()

        # Apply all supporrted tarnsform methods
        header_transport = THeaderTransport(memory_transport)
        header_transport.write_transforms = [Thrift.TransformID.ZLIB, Thrift.TransformID.ZSTD]

        raw_size = 1000
        bytes = rand(UInt8(1):UInt8(4), raw_size)
        write(header_transport, bytes)
        flush(header_transport)

        let compressed_size = bytesavailable(memory_transport.buff)
            @info "Transformed data has $compressed_size bytes (raw size = $raw_size bytes)"
            @test compressed_size < raw_size
        end

        Thrift.read_frame!(header_transport)
        @test header_transport.read_headers["client_metadata"] ==
            "{\"agent\":\"Julia THeaderTransport\"}"
        @test read(header_transport.rbuf) == bytes
    end
end
