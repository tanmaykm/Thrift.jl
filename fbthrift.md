# FBThrift notes

## Binary protocol

How it works when calling the `sendMessage` method:

writeMessageBegin

    0x80, 0x01, 0x00, 0x01

        0x80010000 is the binary protocol
        0x00000001 is Thrift.MessageType.CALL (0x01)
        Need to bitwise-OR these numbers

    0x00, 0x00, 0x00, 0x0b
        length of string (method name)

    0x73, 0x65, 0x6e, 0x64, 0x4d, 0x65, 0x73, 0x73, 0x61, 0x67, 0x65
        "sendMessage"

    0x00, 0x00, 0x00, 0x01
        0x01 is the sequence id

writeFieldBegin

    0x0c
        it's a struct

    0x00, 0x01
        field id = 1  (field it is a 16-bit integer)

    writeFieldBegin

        0x0b
            it's a string

        0x00, 0x01
            field id = 1 (this is the "message" field)

        0x00, 0x00, 0x00, 0x05
            length of the string

        0x68, 0x65, 0x6c, 0x6c, 0x6f
            "hello"

    writeFieldBegin

        0x0b
            it's a string

        0x00, 0x02
            field id = 2 (this is the "sender" field)

        0x00, 0x00, 0x00, 0x03
            length of the string

        0x74, 0x6f, 0x6d
            "tom"

    writeFieldStop
        0x00

writeFieldStop
    0x00

NOTE: Binary protocol does not do anything with `writeMessageEnd`.

## Transports

TODO(tomkwong) The C++ server is responding with this error:

```
E1017 15:57:05.323765 2948565 HeaderServerChannel.cpp:100] Received invalid request from client: apache::thrift::transport::TTransportException: Could not detect client transport type: magic 0x73656e64 (transport apache::thrift::PreReceivedDataAsyncTransportWrapper, address ::ffff:127.0.0.1, port 40468)
```

The mentioned magic 0x73656e64 is the same as the first few bytes of the
method name "send":

```
 's': ASCII/Unicode U+0073 (category Ll: Letter, lowercase)
 'e': ASCII/Unicode U+0065 (category Ll: Letter, lowercase)
 'n': ASCII/Unicode U+006E (category Ll: Letter, lowercase)
 'd': ASCII/Unicode U+0064 (category Ll: Letter, lowercase)
```

Upon further research, it seems that TSocket cannot really be used as a
transport. This page https://www.internalfb.com/intern/wiki/Thrift/Transport/
describes various transports used at FB. At a minimum, we need to use
THeader or Rocket. It also mentions Framed transport, which seems to be
supported by Thrift.jsl, but that is considered deprecated.

In other words, there is no "plain" transport type and that's why just
using TSocket as a transport isn't going to cut it.

The THeader transport format is documented here:
https://www.internalfb.com/code/fbsource/fbcode/thrift/doc/HeaderFormat.md

Searching for "header.*magic" in fbcode/thrift folder yields many of the
existing implementations of THeader protocol. I can use that for inspiration.
