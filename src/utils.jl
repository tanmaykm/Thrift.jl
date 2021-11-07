"""
    tohex(bytes::Vector{UInt8})

Display a byte array in human readable format that is also easy to copy/paste
to REPL to create the same array.
"""
function tohex(bytes::Vector{UInt8})
    s = join(map(s -> "0x$s", bytes2hex.(bytes)), ", ")
    len = length(bytes)
    return "$len bytes: [$s]"
end

tohex(x::Union{UInt8,UInt16,UInt32,UInt64}) = let io = IOBuffer()
    show(io, x)
    String(take!(io))
end
