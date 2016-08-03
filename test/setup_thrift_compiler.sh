#!/usr/bin/env bash

# Script to compile and install a thrift compiler with Julia extensions.
# Used for CI tests.

# apt packages required:
# apt-get install libssl-dev flex bison libboost-all-dev

if [ -z "$THRIFT_DIR" ]
then
    THRIFT_DIR=/thrift
fi

mkdir $THRIFT_DIR && \
cd $THRIFT_DIR && \
git clone https://github.com/tanmaykm/thrift.git && \
cd $THRIFT_DIR/thrift && \
git checkout julia && \
mkdir $THRIFT_DIR/thrift/install && \
cd $THRIFT_DIR/thrift && \
./bootstrap.sh && \
./configure --prefix=$THRIFT_DIR/thrift/install && \
make install
