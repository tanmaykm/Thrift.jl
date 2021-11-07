"""
    tohex(bytes::Vector{UInt8})

Display a byte array in human readable format that is also easy to copy/paste
to REPL to create the same array.
"""
tohex(bytes::Vector{UInt8}) = join(map(s -> "0x$s", bytes2hex.(bytes)), ", ")
