# Thrift SASL transport
#
# Thrift SASL: https://github.com/apache/thrift/blob/master/doc/specs/thrift-sasl-spec.txt
# SASL PLAIN mechanism: https://tools.ietf.org/html/rfc4616

# protocol status codes (also represent SASL negotiation state)
const SASL_ZERO     = 0x00
const SASL_START    = 0x01
const SASL_OK       = 0x02
const SASL_BAD      = 0x03
const SASL_ERROR    = 0x04
const SASL_COMPLETE = 0x05

# sasl mechanism names
const SASL_MECH_PLAIN   = "PLAIN"
const SASL_MECH_KERB    = "KERBEROS"
const SASL_MECH_LDAP    = "LDAP"
const SASL_MECHANISMS   = (SASL_MECH_PLAIN, SASL_MECH_KERB, SASL_MECH_LDAP)

# sasl exception types
const SASL_ERR_UNKNOWN      = 0
const SASL_ERR_UNSUPPORTED  = 1
const SASL_ERR_NEGOTIATION  = 2
const SASL_ERR_INVALID      = 3

struct SASLException <: Exception
    code::Int
    message::AbstractString

    SASLException(code=SASL_ERR_UNKNOWN, message::AbstractString="") = new(code, message)
end

validate_sasl_mech(mech) = (mech in SASL_MECHANISMS) || throw(SASLException(SASL_ERR_UNSUPPORTED, "Unsupported SASL mechanism \"$mech\""))

validate_sasl_status(status::UInt8, message::Vector{UInt8}, okstatus::Tuple) = validate_sasl_status(status, String(message), okstatus)
function validate_sasl_status(status::UInt8, message::AbstractString, okstatus::Tuple)
    (status != SASL_BAD) && (status != SASL_ERROR) && (status in okstatus) && return

    if status == SASL_BAD
        msg = "SASL mechanism not supported"
        err = SASL_ERR_UNSUPPORTED
    elseif status == SASL_ERROR
        msg = "SASL negotiation failed"
        err = SASL_ERR_NEGOTIATION
    else
        msg = "SASL negotiation failed: unexpected status code $status received from server"
        err = SASL_ERR_NEGOTIATION
    end

    if !isempty(message)
        msg = string(msg, ": ", message)
    end
    throw(SASLException(err, msg))
end

# SASL messages are of the form:
# | 1-byte status code | 4-byte payload length | variable-length payload |
sasl_write(io::IO, status::UInt8, payload::AbstractString) = sasl_write(io, status, convert(Vector{UInt8}, codeunits(payload)))
function sasl_write(io::IO, status::UInt8, payload::Vector{UInt8}=UInt8[])
    len = length(payload)
    iob = IOBuffer()
    write(iob, status)
    _write_fixed(iob, UInt32(len), true)
    (len > 0) && write(iob, payload)
    write(io, take!(iob))
end

function sasl_read(io::IO)
    status = read(io, UInt8)
    @debug("read_sasl", status)
    len = _read_fixed(io, UInt32(0), 4, true)
    @debug("read_sasl", len)
    data = read!(io, Vector{UInt8}(undef, len))
    @debug("read_sasl", data)
    (status, len, data)
end

function sasl_negotiate_plain(io::IO, callback::Function)
    # prepare credentials
    authzid = callback(:authzid)
    authcid = callback(:authcid)
    password = callback(:passwd)
    (isempty(authcid) || isempty(password)) && throw(SASLException(SASL_ERR_INVALID, "Invalid or empty credentials"))
    (max(length(authcid), length(password), length(authzid)) > 255) && throw(SASLException(SASL_ERR_INVALID, "Credentials too large"))

    creds = IOBuffer()
    isempty(authzid) || creds.write(convert(Vector{UInt8}, codeunits(authzid)))
    write(creds, 0x00)
    write(creds, convert(Vector{UInt8}, codeunits(authcid)))
    write(creds, 0x00)
    write(creds, convert(Vector{UInt8}, codeunits(password)))

    # start negotiation, indicate protocol
    nbyt = sasl_write(io, SASL_START, SASL_MECH_PLAIN)
    @debug("negotiate_sasl wrote", nbyt)
    # send credentials
    nbyt = sasl_write(io, SASL_OK, take!(creds))
    @debug("negotiate_sasl wrote", nbyt)

    (status, len, data) = sasl_read(io)
    @debug("negotiate_sasl read", status, len, data)
    validate_sasl_status(status, data, (SASL_COMPLETE,))

    # send COMPLETE
    #nbyt = sasl_write(io, SASL_COMPLETE, "")
    #@debug("negotiate_sasl wrote $nbyt bytes")

    nothing
end

function sasl_negotiate(io::IO, mech, callback::Function)
    if mech == SASL_MECH_PLAIN
        return sasl_negotiate_plain(io, callback)
    end
    throw(SASLException(SASL_ERR_UNSUPPORTED, "Unsupported mechanism $mech"))
end

function sasl_callback_default(part::Symbol)
    (part == :authcid) && (return get(ENV, "USER", ""))
    (part == :passwd) && (return "password")
    (part == :show) && (return get(ENV, "USER", ""))
    (part == :mechanism) && (return "SASL-Plain")

    return "" # for authzid
end
