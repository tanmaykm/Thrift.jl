
type _enum_TProtocolExceptionTypes
    UNKNOWN::Int32
    INVALID_DATA::Int32
    NEGATIVE_SIZE::Int32
    SIZE_LIMIT::Int32
    BAD_VERSION::Int32
end

const ProtocolExceptionType = _enum_TProtocolExceptionTypes(0, 1, 2, 3, 4)

type TProtocolException
    typ::Int32
    message::String

    TProtocolException(typ::Int32=ProtocolExceptionType.UNKNOWN, message::String="") = new(typ, message)
end

