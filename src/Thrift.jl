module Thrift

using Distributed
using Sockets
using ThriftJuliaCompiler_jll

using CodecZlib
using CodecZstd
using TranscodingStreams

import Sockets: TCPServer, listen, accept
import Base: open, close, isopen, read, read!, write, flush, skip, show, copy!, hasproperty, getproperty, setproperty!, propertynames

export open, close, isopen, read, read!, write, flush, skip, listen, accept, show, copy!

# from base.jl
export TSTOP, TVOID, TBOOL, TBYTE, TI08, TDOUBLE, TI16, TI32, TI64, TSTRING, TUTF7, TSTRUCT, TMAP, TSET, TLIST, TUTF8, TUTF16
export TType, TProcessor, TTransport, TServerTransport, TServer, TProtocol
export writeMessageBegin, writeMessageEnd, writeStructBegin, writeStructEnd, writeFieldBegin, writeFieldEnd, writeFieldStop, writeMapBegin, writeMapEnd, writeListBegin, writeListEnd, writeSetBegin, writeSetEnd, writeBool, writeByte, writeI16, writeI32, writeI64, writeDouble, writeString
export readMessageBegin, readMessageEnd, readStructBegin, readStructEnd, readFieldBegin, readFieldEnd, readMapBegin, readMapEnd, readListBegin, readListEnd, readSetBegin, readSetEnd, readBool, readByte, readI16, readI32, readI64, readDouble, readString
export ApplicationExceptionType, MessageType, TException, TApplicationException
export ThriftMetaAttribs, ThriftMeta, meta
export isinitialized, set_field!, get_field, clear, has_field, fillunset, isfilled, thriftbuild, enumstr

# from transports.jl
export TFramedTransport, TSASLClientTransport, TSocket, TServerSocket, TSocketBase, TMemoryTransport, TFileTransport, THeaderTransport
export TransportExceptionTypes, TTransportException

# from sasl.jl
export SASL_MECH_PLAIN, SASL_MECH_KERB, SASL_MECH_LDAP, SASLException

# from protocols.jl
export TBinaryProtocol, TCompactProtocol, THeaderProtocol

# from processor.jl
export ThriftProcessor, ThriftHandler, process, handle, extend, distribute

# from server.jl
export TSimpleServer, TTaskServer, TProcessPoolServer, serve

function generate(idl_file::String; dir::String=pwd())
    thrift() do thrift_cmd
        run(Cmd(`$thrift_cmd -gen jl $idl_file`; dir=dir))
    end
end

include("base.jl")
include("codec.jl")
include("sasl.jl")
include("transports.jl")
include("protocols.jl")
include("processor.jl")
include("server.jl")
include("utils.jl")

end # module
