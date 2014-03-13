module Thrift

import Base.TcpSocket, Base.TcpServer
import Base.open, Base.close, Base.isopen, Base.read, Base.write, Base.flush, Base.skip, Base.listen, Base.accept

export open, close, isopen, read, write, flush, skip, listen, accept


# from base.jl
export TSTOP, TVOID, TBOOL, TBYTE, TI08, TDOUBLE, TI16, TI32, TI64, TSTRING, TUTF7, TSTRUCT, TMAP, TSET, TLIST, TUTF8, TUTF16
export TType, TProcessor, TTransport, TServerTransport, TServer, TProtocol
export writeMessageBegin, writeMessageEnd, writeStructBegin, writeStructEnd, writeFieldBegin, writeFieldEnd, writeFieldStop, writeMapBegin, writeMapEnd, writeListBegin, writeListEnd, writeSetBegin, writeSetEnd, writeBool, writeByte, writeI16, writeI32, writeI64, writeDouble, writeString
export readMessageBegin, readMessageEnd, readStructBegin, readStructEnd, readFieldBegin, readFieldEnd, readMapBegin, readMapEnd, readListBegin, readListEnd, readSetBegin, readSetEnd, readBool, readByte, readI16, readI32, readI64, readDouble, readString
export ApplicationExceptionType, MessageType, TException, TApplicationException


# from transports.jl
export TFramedTransport, TSocket, TServerSocket, TSocketBase
export TransportExceptionTypes, TTransportException


# from protocols.jl
export TBinaryProtocol


# from processor.jl
export ThriftProcessor, ThriftHandler, process, handle


# from server.jl
export TSimpleServer, serve


include("base.jl")
include("codec.jl")
include("transports.jl")
include("protocols.jl")
include("processor.jl")
include("server.jl")

end # module

