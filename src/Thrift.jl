module Thrift

using Distributed
using Sockets
using ThriftJuliaCompiler_jll
using HTTP

import Sockets: TCPServer, listen, accept
import Base: open, close, isopen, read, read!, write, flush, skip, show, copy!

export open, close, isopen, read, read!, write, flush, skip, listen, accept, show, copy!

# from base.jl
export TSTOP, TVOID, TBOOL, TBYTE, TI08, TDOUBLE, TI16, TI32, TI64, TSTRING, TUTF7, TSTRUCT, TMAP, TSET, TLIST, TUTF8, TUTF16
export TType, TProcessor, TTransport, TServerTransport, TServer, TProtocol
export writeMessageBegin, writeMessageEnd, writeStructBegin, writeStructEnd, writeFieldBegin, writeFieldEnd, writeFieldStop, writeMapBegin, writeMapEnd, writeListBegin, writeListEnd, writeSetBegin, writeSetEnd, writeBool, writeByte, writeI16, writeI32, writeI64, writeDouble, writeString
export readMessageBegin, readMessageEnd, readStructBegin, readStructEnd, readFieldBegin, readFieldEnd, readMapBegin, readMapEnd, readListBegin, readListEnd, readSetBegin, readSetEnd, readBool, readByte, readI16, readI32, readI64, readDouble, readString
export ApplicationExceptionType, MessageType, TException, TApplicationException
export ThriftMetaAttribs, ThriftMeta, meta
export isinitialized, set_field, set_field!, get_field, clear, has_field, fillunset, fillset, filled, isfilled, thriftbuild, enumstr

# from transports.jl
export TFramedTransport, TSASLClientTransport, TSocket, TServerSocket, TSocketBase, TMemoryTransport, TFileTransport
export TransportExceptionTypes, TTransportException

# from sasl.jl
export SASL_MECH_PLAIN, SASL_MECH_KERB, SASL_MECH_LDAP, SASLException

# from protocols.jl
export TBinaryProtocol, TCompactProtocol

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

end # module
