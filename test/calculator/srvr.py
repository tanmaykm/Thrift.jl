#!/usr/bin/env python

import sys
sys.path.append('./gen-py')

from arithmetic import Calc
from arithmetic.ttypes import *
from floatops.ttypes import *

from thrift.transport import TSocket
from thrift.transport import TTransport
from thrift.protocol import TBinaryProtocol, TCompactProtocol
from thrift.server import TServer

import socket

class CalcHandler:
    def __init__(self):
        self.log = {}

    def calculate(self, oper, p1, p2):
        if(oper == "+"):
            ret = (p1 + p2)
        elif(oper == "-"):
            ret = (p1 - p2)
        elif(oper == "*"):
            ret = (p1 * p2)
        elif(oper == "^"):
            ret = (p1 ** p2)
        else:
            raise InvalidOperation(oper)

        if ret > ((2**31)-1):
            raise InvalidOperation("%s(%d,%d) overflows"%(oper,p1,p2))

        return ret

    def float_calculate(self, oper, p1, p2):
        if(oper == "+"):
            ret = (p1 + p2)
        elif(oper == "-"):
            ret = (p1 - p2)
        elif(oper == "*"):
            ret = (p1 * p2)
        else:
            raise InvalidFloatOperation(oper)

        if ret > ((2**63)-1):
            raise InvalidFloatOperation("%s(%f,%f) overflows"%(oper,p1,p2))

        return ret


handler = CalcHandler()
processor = Calc.Processor(handler)
transport = TSocket.TServerSocket(port=19999)
tfactory = TTransport.TBufferedTransportFactory()
pfactory = TBinaryProtocol.TBinaryProtocolFactory()
#pfactory = TCompactProtocol.TCompactProtocolFactory()

server = TServer.TSimpleServer(processor, transport, tfactory, pfactory)

print "Starting python server..."
server.serve()
print "done!"

