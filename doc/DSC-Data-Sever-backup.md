# DSC/Data server backup plan

0. problem statement
--------
Some reason cause root server can't upload data to yeti data storage server.
such as network failure, middlebox or other problems. so we want to fix this
problem. 

One simple method is to add a backup server on a different location. We update 
the upload code to use "SRV" records so that the upload process automatically 
falls back to a secondary location.
 
1. srv records:
---------
    srv:
    _data._tcp.yeti-dns.org  0 1 22 data.yeti-dns.org     # BII
    _data._tcp.yeti-dns.org  0 2 22 backup.yeti-dns.org    # VPS

2. data store
---------
    2.1 BII lab: store all data
    2.2 VPS:  vultr datacenter in europe, only store data when root servers can't connect to BII lab
    
3. sync data
---------
    rsync:
        backup.yeti-dns.org-> data.yeti-dns.org

4 change
--------
    4.1 update root server monitoring script 
        add srv records support for data storage server.
        change data sgorage server domain name
        add wrapsrv function support
        add dnscap guard script in case of dnscap crash.
        handle the case both BII and VPS are unreachable

    4.2 rsync data from VPS to BII, delete the data on VPS
         
5. procedure
---------
    5.1 normal
        root server upload pcap to data storage server
    5.2 network problem
        root server upload pcap to backup data storage server
    5.3 rsync data from VPS to BII
         we will get notified if any of these rsync fails.
    
    5.4. other problems
        when network outside of root server is broken. 
        but root server still caputre dns packets, and root server can't upload
        data to BII or VPS server。
   
     we will notice it and contact the operator
   
