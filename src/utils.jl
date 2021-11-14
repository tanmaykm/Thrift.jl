"""
    tohex(x)

Display `x` in human readable format that is also easy to copy/paste
to REPL to re-create the data.
"""
function tohex end

function tohex(bytes::Vector{UInt8})
    s = join(map(s -> "0x$s", bytes2hex.(bytes)), ", ")
    len = length(bytes)
    return "$len bytes: [$s]"
end

tohex(x::Integer) = "0x" * string(x; base = 16)

"""
    extract(x, type, pos = 1)

Extract data from an array `x` at position `pos` with the target `type`.
For integral data, the array `x` is assumed to be in Network byte ordre
(big-endian).

For example:
```
julia> x = [0x00, 0x01, 0x00, 0x02]
4-element Vector{UInt8}:
 0x00
 0x01
 0x00
 0x02

julia> extract(x, Int16, 1)
1

julia> extract(x, UInt16, 3)
0x0002
```
"""
function extract(x::Vector{UInt8}, type::Type{<:Integer}, pos::Integer = 1)
    end_pos = pos + sizeof(type) - 1
    return ntoh(reinterpret(type, x[pos:end_pos])[1])
end

"""
    peek_buffer(buf::IOBuffer, label::AbstractString)

Display debug messaging with the buffer's content.
"""
function peek_buffer(buf::IOBuffer, label::AbstractString)
    n = bytesavailable(buf)
    @debug "$label($n bytes)" tohex(buf.data[1:n])
end

# Borrowed from protocol.jl
writeVarint(io::IO, i::T) where {T <: Integer} = _write_uleb(io, i)
readVarint(io::IO, t::Type{T}=Int64) where {T <: Integer} = _read_uleb(io, t)
