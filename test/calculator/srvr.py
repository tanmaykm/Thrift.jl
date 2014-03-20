#!/usr/bin/env python

import sys
sys.path.append('./gen-py')

from arithmetic import Calc
from arithmetic.ttypes import *

from thrift.transport import TSocket
from thrift.transport import TTransport
from thrift.protocol import TBinaryProtocol
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
            #ret = 0
            raise InvalidOperation("%s(%d,%d) overflows"%(oper,p1,p2))

        return ret

handler = CalcHandler()
processor = Calc.Processor(handler)
transport = TSocket.TServerSocket(port=9999)
tfactory = TTransport.TBufferedTransportFactory()
pfactory = TBinaryProtocol.TBinaryProtocolFactory()

server = TServer.TSimpleServer(processor, transport, tfactory, pfactory)

print "Starting python server..."
server.serve()
print "done!"

