#!/bin/bash

#
# install dnscap and wrapsrv
# usage: sh setup.sh  # will install both dnscap and wrapsrv
# usage: sh setup.sh dnscap # will install dnscap only
# usage: sh setup.sh wrapsrv # will install wrapsrv only
# 
#

dnscap_url="https://github.com/verisign/dnscap"
wrapsrv_url="https://github.com/farsightsec/wrapsrv"

install_dnscap() {
    cd dnscap
    make clean && ./configure && make && make install
    cd ..
}

install_wrapsrv() {

    local OS=`uname -s`
    
    cd wrapsrv
    make clean

    if [ "$OS" = "FreeBSD" ]; then
        make CC=cc LDFLAGS=""
    elif [ "$OS" = "Linux" ]; then
        make
    else
        make
    fi
    
    make install
    cd ..
}

download() {
    if  git clone $1; then
        echo "download $1 successfully"
    else
        echo "error: download $1 Failed"
        exit 1
    fi
}

check_tools() {

    local tools=$1

    for x in $tools
    do
        echo "checking $x"
        if which $x > /dev/null; then
            echo "$x.....ok"
        else
            echo "error: missing $x, please install $x"
            exit 1
        fi
    done
}

default_install() {
    if [ ! -d dnscap ]; then
        download "$dnscap_url"
    fi
    install_dnscap
    
    if [ ! -d wrapsrv ]; then
        download "$wrapsrv_url"
    fi
    install_wrapsrv
}

usage() {
    echo "sh ./$0 [dnscap|wrapsrv]"
    exit 1
}

check_tools "cc make git"

if [ $# -eq 0 ]; then
    default_install
elif [ "$1" = "dnscap" ]; then
    [ ! -d dnscap ] && download "$dnscap_url"
    install_dnscap
elif [ "$1" = "wrapsrv" ]; then
    [ ! -d wrapsrv ] && download "$wrapsrv_url"
    install_wrapsrv
else
    usage
fi
