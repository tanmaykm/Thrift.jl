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

tohex(x::Unsigned) = "0x" * string(x; base = 16)
