import yaml
import sys

def generate_NS_list():
    with open(sys.argv[2]) as f:
        for server in yaml.load(f):
            print('{0}   {1}'.format(server['name'], server['public_ip']))

def generate_zonetransfer():
    print "acl zonetransfer {"

    with open(sys.argv[2]) as f:
        for server in yaml.load(f):
            if server.get('transfer_net') is not None:
                for s in server['transfer_net']:
                    print('    {0};'.format(s))
            else:
                print('    {0};'.format(server['public_ip']))

    print "};"

def generate_ACL():
    print "masters notifyroot {"

    with open(sys.argv[2]) as f:
        for server in yaml.load(f):
            if server.get('notify_addr') is not None:
                for s in server['notify_addr']:
                    print('    {0};'.format(s))
            else:
                print('    {0};'.format(server['public_ip']))

    print "};"

def useage():
    print('Usage:   python parseyaml.py {ns|acl|notify} yamlfile')
    print('Example: python parseyaml.py ns yeti-root-servers.yaml')

if len(sys.argv) != 3:
    useage()
    sys.exit(1)
elif sys.argv[1] == "ns": 
    generate_NS_list()
elif sys.argv[1] == "acl":
    generate_zonetransfer()
elif sys.argv[1] == "notify":
    generate_ACL() 
else:
    useage()
    sys.exit(1)
