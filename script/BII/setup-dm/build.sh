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

# install python module: pip, yaml, argparse
# for Centos 6
rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
yum install -y python-pip
pip install -y pyaml argparse

# install ldns
yum install -y ldns

