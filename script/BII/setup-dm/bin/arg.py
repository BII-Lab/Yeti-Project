import argparse
import sys
"""
addserver domain addr
delserver domina
renumber server domain newaddr
rename server domain newdomin

addtransfer domain addr
deltransfer domain addr
updatetransfer domain oldaddr newaddr

addnotify domain addr
delnotify domain addr
updatenotify domain oldaddr newaddr
"""
parser = argparse.ArgumentParser(prog=sys.argv[0])

subparsers = parser.add_subparsers(help='sub-command help')

addserver = subparsers.add_parser('addserver', help='addserver domain addr yamlfile')
addserver.add_argument('domain', type=str, help='domain name')
addserver.add_argument('addr', type=str, help='address ')
addserver.add_argument('yamlfile', type=str, help='yaml file path ')

delserver = subparsers.add_parser('delserver', help='delserver domain yamlfile')
delserver.add_argument('domain', type=str, help='domain name')
delserver.add_argument('yamlfile', type=str, help='yaml file path ')

renumber = subparsers.add_parser('renumber', help='renumber domain addr yamlfile')
renumber.add_argument('domain', type=str, help='domain name')
renumber.add_argument('addr', type=str, help='new address ')
renumber.add_argument('yamlfile', type=str, help='yaml file path ')

rename = subparsers.add_parser('rename', help='rename domain addr yaml file')
rename.add_argument('domain', type=str, help='domain name')
rename.add_argument('addr', type=str, help='new address ')
rename.add_argument('yamlfile', type=str, help='yaml file path ')

addtransfer = subparsers.add_parser('addtransfer', help='addtransfer domain addr yamlfile')
addtransfer.add_argument('domain', type=str, help='domain name')
addtransfer.add_argument('addr', type=str, help='new address ')
addtransfer.add_argument('yamlfile', type=str, help='yaml file path ')

deltransfer = subparsers.add_parser('deltransfer', help='deltransfer  domain addr yamlfile')
deltransfer.add_argument('domain', type=str, help='domain name')
deltransfer.add_argument('addr', type=str, help='address ')
deltransfer.add_argument('yamlfile', type=str, help='yaml file path ')

updatetransfer = subparsers.add_parser('updatetransfer', help='updatetransfer  domain oldaddr newaddr yamlfile')
updatetransfer.add_argument('domain', type=str, help='domain name')
updatetransfer.add_argument('oldaddr', type=str, help='old address ')
updatetransfer.add_argument('newaddr', type=str, help='new address ')
updatetransfer.add_argument('yamlfile', type=str, help='yaml file path ')

addnotify = subparsers.add_parser('addnotify', help='addnotify  domain addr yamlfile')
addnotify.add_argument('domain', type=str, help='domain name')
addnotify.add_argument('addr', type=str, help='new address ')
addnotify.add_argument('yamlfile', type=str, help='yaml file path ')

delnotify = subparsers.add_parser('delnotify', help='delnotify  domain addr yamlfile')
delnotify.add_argument('domain', type=str, help='domain name')
delnotify.add_argument('addr', type=str, help='address ')
delnotify.add_argument('yamlfile', type=str, help='yaml file path ')

updatenotify = subparsers.add_parser('updatenotify', help='updatenotify  domain oldaddr newaddr  yamlfile')
updatenotify.add_argument('domain', type=str, help='domain name')
updatenotify.add_argument('oldaddr', type=str, help='old address ')
updatenotify.add_argument('newaddr', type=str, help='new address ')
updatenotify.add_argument('yamlfile', type=str, help='yaml file path ')

