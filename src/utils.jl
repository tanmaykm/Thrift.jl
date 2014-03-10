abstract TProcessor

abstract TExceptionBase <: Exception

type TException <: TExceptionBase
    message::String
end

type _enum_TApplicationExceptionTypes
    UNKNOWN::Int32
    UNKNOWN_METHOD::Int32
    INVALID_MESSAGE_TYPE::Int32
    WRONG_METHOD_NAME::Int32
    BAD_SEQUENCE_ID::Int32
    MISSING_RESULT::Int32
    INTERNAL_ERROR::Int32
    PROTOCOL_ERROR::Int32
    INVALID_TRANSFORM::Int32
    INVALID_PROTOCOL::Int32
    UNSUPPORTED_CLIENT_TYPE::Int32
end

const ApplicationExceptionType = _enum_TApplicationExceptionTypes(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
const _appex_msgs = [
    "Default (unknown) TApplicationException",
    "Unknown method",
    "Invalid message type",
    "Wrong method name",
    "Bad sequence ID",
    "Missing result",
    "Internal error",
    "Protocol error",
    "Invalid transform",
    "Invalid protocol",
    "Unsupported client type"
]

type TApplicationException <: TExceptionBase
    typ::Int32
    message::String

    TApplicationException(typ::Int32=ApplicationExceptionType.UNKNOWN, message::String="") = new(typ, isempty(message) ? _appex_msgs[typ] : message)
end

type _enum_TMessageType
    CALL::Int32
    REPLY::Int32
    EXCEPTION::Int32
    ONEWAY::Int32
end

const MessageType = _enum_TMessageType(1, 2, 3, 4)

