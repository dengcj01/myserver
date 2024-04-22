#!/bin/bash
export LD_LIBRARY_PATH=/data/home/gameServerProject/libs
./protoc -I=./protobuf --cpp_out=./common/pb ./protobuf/ServerCommon.proto

