import yaml
import sys
import arg

def parseyaml(file):
    """parse yaml file, return lists"""
    with open(file) as f:
        dataMap = yaml.load(f)
        return dataMap

def addroot(domain, address, yetiserver):
    """ append root server to lists yetiserver"""
    #print domain, address, yetiserver
    s = dict(name=domain, public_ip=address)
    if yetiserver is not None:
        yetiserver.append(s)
    else: 
        yetiserver = []
        yetiserver.append(s)

def delroot(domain, yetiserver):
    """ delete root server from lists yetiserver"""
    for i in range(len(yetiserver)):
        #print  i, yetiserver[i]['name'], domain
        if yetiserver[i]['name'] == domain:
            del yetiserver[i]
            return

def renumber(domain, newaddr, yetiserver):
    """ chang root server address in lists yetiserver"""
    #print domain, newaddr, yetiserver
    for i in range(len(yetiserver)):
        if yetiserver[i]['name'] == domain:
            yetiserver[i]['public_ip'] = newaddr
            return

def rename(domain, newdomain, yetiserver):
    """ chang root server domain in lists yetiserver"""
    #print domain, newdomain, yetiserver
    for i in range(len(yetiserver)):
        if yetiserver[i]['name'] == domain:
            yetiserver[i]['name'] = newdomain
            return

def addnotify(domain, notifyaddr, yetiserver):
    """ add notify address for root server"""
    for i in range(len(yetiserver)):
        #print  i, yetiserver[i]['name'], domain
        if yetiserver[i]['name'] == domain:
            if yetiserver[i].get('notify_addr') is not None:
                yetiserver[i]['notify_addr'].append(notifyaddr)
            else:
                yetiserver[i]['notify_addr'] = []
                yetiserver[i]['notify_addr'].append(notifyaddr)
            return

def delnotify(domain, notifyaddr, yetiserver):
    """ del notify address for root server"""
    for i in range(len(yetiserver)):
        #print  i, yetiserver[i]['name'], domain
        if yetiserver[i]['name'] == domain:
            for j in range(len(yetiserver[i]['notify_addr'])):
                if yetiserver[i]['notify_addr'][j] == notifyaddr:
                    del yetiserver[i]['notify_addr'][j]
                    if len(yetiserver[i]['notify_addr']) == 0:
                        del yetiserver[i]['notify_addr']
                    return

def updatenotify(domain, oldaddr, newaddr, yetiserver):
    """ del notify address for root server"""
    for i in range(len(yetiserver)):
        #print  i, yetiserver[i]['name'], domain
        if yetiserver[i]['name'] == domain:
            for j in range(len(yetiserver[i]['notify_addr'])):
                if yetiserver[i]['notify_addr'][j] == oldaddr:
                    yetiserver[i]['notify_addr'][j] = newaddr
                    return

def addtransfer(domain, addr, yetiserver):
    """ add transfer address for root server"""
    for i in range(len(yetiserver)):
        #print  i, yetiserver[i]['name'], domain
        if yetiserver[i]['name'] == domain:
            if yetiserver[i].get('transfer_net') is not None:
                yetiserver[i]['transfer_net'].append(addr)
            else:
                yetiserver[i]['transfer_net'] = []
                yetiserver[i]['transfer_net'].append(addr)
            return

def deltransfer(domain, addr, yetiserver):
    """ del transfer address for root server"""
    for i in range(len(yetiserver)):
        #print  i, yetiserver[i]['name'], domain
        if yetiserver[i]['name'] == domain:
            for j in range(len(yetiserver[i]['transfer_net'])):
                if yetiserver[i]['transfer_net'][j] == addr:
                    del yetiserver[i]['transfer_net'][j]
                    if len(yetiserver[i]['transfer_net']) == 0:
                        del yetiserver[i]['transfer_net']
                    return

def updatetransfer(domain, oldaddr, newaddr, yetiserver):
    """ update notify address for root server"""
    for i in range(len(yetiserver)):
        #print  i, yetiserver[i]['name'], domain
        if yetiserver[i]['name'] == domain:
            for j in range(len(yetiserver[i]['transfer_net'])):
                if yetiserver[i]['transfer_net'][j] == oldaddr:
                    yetiserver[i]['transfer_net'][j] = newaddr
                    return

def generateyaml(file, yetiserver):
    """ generate yaml file from lists yetiserver"""
    with open(file, 'w') as f:
        yaml.dump(yetiserver, f, default_flow_style=False, indent=2)

ftable=dict(addserver=addroot, delserver=delroot, \
               renumber=renumber, rename=rename, \
               addtransfer=addtransfer, deltransfer=deltransfer, \
               updatetransfer=updatetransfer, \
               addnotify=addnotify, delnotify=delnotify, \
               updatenotify=updatenotify)

if __name__ == "__main__":
    arg.parser.parse_args(sys.argv[1:])
    yamlfile = sys.argv[-1]
    func = sys.argv[1]
    argment = sys.argv[2:-1]

    servers = parseyaml(yamlfile)
    ftable[func](*(argment+[servers]))
    generateyaml(yamlfile, servers)

