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

