#!/usr/bin/env python

import sys, random
sys.path.append('./gen-py')

from arithmetic import Calc
from arithmetic.ttypes import *
from arithmetic.constants import *

from thrift import Thrift
from thrift.transport import TSocket
from thrift.transport import TTransport
from thrift.protocol import TBinaryProtocol

def calcclnt(niter):
    try:
        # Make socket
        transport = TSocket.TSocket('localhost', 9999)

        # Buffering is critical. Raw sockets are very slow
        transport = TTransport.TBufferedTransport(transport)

        # Wrap in a protocol
        protocol = TBinaryProtocol.TBinaryProtocol(transport)

        # Create a client to use the protocol encoder
        client = Calc.Client(protocol)

        # Connect!
        print("opening connection. " + str(transport))
        transport.open()
        print("opened connection. " + str(transport))

        for idx in range(0, niter):
            try:
                oper = random.choice(OPS)
                p1 = random.randint(1, 100)
                p2 = random.randint(1, 100)
                ret = client.calculate(oper, p1, p2)
                print("%s(%d, %d) = %d"%(oper, p1, p2, ret))
            except Thrift.TException, tx:
              print "%s" % (tx.oper)

        transport.close()
        print("closed connection. " + str(transport))

    except Thrift.TException, tx:
      print "%s" % (tx.message)

for idx in range(0,5):
    calcclnt(10)

