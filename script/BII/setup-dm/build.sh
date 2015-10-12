#!/bin/bash

# install golang
# netbsd: pkgin install bash git
# Linux
# FreeBSD
# set GOPATH

if which go; then
    cd bin/
    go build checkns.go
    go build parsednskey.go
    cd -
else
   echo "can not find go, please install go" 
   exit 1
fi
