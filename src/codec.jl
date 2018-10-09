const MSB = 0x80
const MASK7 = 0x7f
const MASK8 = 0xff

const _wfbuf = (Vector{UInt8}(undef, 1), Vector{UInt8}(undef, 2), Vector{UInt8}(undef, 4), Vector{UInt8}(undef, 8), Vector{UInt8}(undef, 16))

const TIO = Union{IO, TTransport}

function _write_fixed(io::TIO, ux::T, bigendian::Bool) where T <: Unsigned
    N = sizeof(ux)
    _write_fixed(io, ux, _wfbuf[Int(log2(N))+1], bigendian ? (N:-1:1) : (1:N))
end

function _write_fixed(io::TIO, ux::T, a::Vector{UInt8}, r::R) where {T <: Unsigned, R <: AbstractRange}
    for n in r
        a[n] = UInt8(ux & MASK8)
        ux >>>= 8
    end
    write(io, a)
end

function _read_fixed(io::TIO, ret::T, N::Int, bigendian::Bool) where T <: Unsigned
    r = bigendian ? ((N-1):-1:0) : (0:1:(N-1))
    for n in r
        byte = convert(T, read(io, UInt8))
        ret |= (byte << (8*n))
    end
    ret
end

function _write_uleb(io::TIO, x::T) where T <: Integer
    nw = 0
    cont = true
    while cont
        byte = x & MASK7
        if (x >>>= 7) != 0
            byte |= MSB
        else
            cont = false
        end
        nw += write(io, UInt8(byte))
    end
    nw
end

function _read_uleb(io::TIO, typ::Type{T}) where T <: Integer
    res = convert(typ, 0)
    n = 0
    byte = UInt8(MSB)
    while (byte & MSB) != 0
        byte = read(io, UInt8)
        res |= (convert(typ, byte & MASK7) << (7*n))
        n += 1
    end
    res
end

function _write_zigzag(io::TIO, x::T) where T <: Integer
    nbits = 8*sizeof(x)
    zx = xor((x << 1), (x >> (nbits-1)))
    _write_uleb(io, zx)
end

function _read_zigzag(io::TIO, typ::Type{T}) where T <: Integer
    zx = _read_uleb(io, UInt64)
    # result is positive if zx is even
    convert(typ, iseven(zx) ? (zx >>> 1) : -((zx+1) >>> 1))
end
