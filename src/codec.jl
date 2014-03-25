const MSB = 0x80
const MASK7 = 0x7f
const MASK8 = 0xff

function _write_fixed{T <: Unsigned}(io, ux::T, bigendian::Bool)
    N = sizeof(ux)
    a = Array(Uint8, N)
    for n in 1:N
        a[bigendian ? (N+1-n) : n] = uint8(ux & MASK8)
        ux >>>= 8
    end
    write(io, a)
    N
end

function _read_fixed{T <: Unsigned}(io, ret::T, N::Int, bigendian::Bool)
    r = bigendian ? ((N-1):-1:0) : (0:1:(N-1))
    for n in r
        byte = convert(T, read(io, Uint8))
        ret |= (byte << 8*n)
    end
    ret
end

function _write_uleb{T <: Integer}(io, x::T)
    nw = 0
    cont = true
    while cont
        byte = x & MASK7
        if (x >>>= 7) != 0
            byte |= MSB
        else
            cont = false
        end
        nw += write(io, uint8(byte))
    end
    nw
end

function _read_uleb{T <: Integer}(io, typ::Type{T})
    res = convert(typ, 0)
    n = 0
    byte = uint8(MSB)
    while (byte & MSB) != 0
        byte = read(io, Uint8)
        res |= (convert(typ, byte & MASK7) << (7*n))
        n += 1
    end
    res
end

function _write_zigzag{T <: Integer}(io, x::T)
    nbits = 8*sizeof(x)
    zx = (x << 1) $ (x >> (nbits-1))
    _write_uleb(io, zx)
end

function _read_zigzag{T <: Integer}(io, typ::Type{T})
    zx = _read_uleb(io, Uint64)
    # result is positive if zx is even
    convert(typ, iseven(zx) ? (zx >>> 1) : -((zx+1) >>> 1))
end

