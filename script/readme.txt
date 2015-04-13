the Script instructions
then gen_root/sh Script has realized automatic download root.zone.gz? root.zone.gz.md?arpa.zone.gz?arpa.zone.gz.md from http://www.internic.net/domain or ftpftp://ftp.internic.net/domain/. and 


1、create directory and files

[root@root1-3 scripts]# tree /root/scripts/
/root/scripts/
├── app_data
│   ├── arpa.zone
│   ├── ftpdownload.txt
│   ├── root.zone
│   └── wwwdownload.txt
├── gen_key.sh
├── gen_root.sh
├── key
│   ├── arpa
│   │   ├── Karpa.+008+24303.key
│   │   ├── Karpa.+008+24303.private
│   │   ├── Karpa.+008+38779.key
│   │   ├── Karpa.+008+38779.private
│   │   ├── Karpa.+008+41370.key
│   │   └── Karpa.+008+41370.private
│   └── root
│       ├── K.+008+17880.key
│       ├── K.+008+17880.private
│       ├── K.+008+24439.key
│       ├── K.+008+24439.private
│       ├── K.+008+28626.key
│       └── K.+008+28626.private
├── ori_data
├── tmp_data
└── zone_data



#mkdir -p /root/scripts/{app_data,ori_data,tmp_data,zone_data,key}
#mkdir -p /root/scripts/key/{root,arpa}



2、create files
[root@root1-3 app_data]# more /root/scripts/app_data/*
::::::::::::::
/root/scripts/app_data/arpa.zone
::::::::::::::
arpa.                       86400   IN      SOA  bii-1.dnsv6lab.net. dnsv6lab.net.     2015041101 1800 900 604800 86400
arpa.       3600000 IN      NS       bii-1.dnsv6lab.net.
arpa.       3600000 IN      NS        bii-2.dnsv6lab.net.
::::::::::::::
/root/scripts/app_data/ftpdownload.txt
::::::::::::::
ftp://ftp.internic.net/domain/arpa.zone.gz
ftp://ftp.internic.net/domain/arpa.zone.gz.md5 
ftp://ftp.internic.net/domain/root.zone.gz 
ftp://ftp.internic.net/domain/root.zone.gz.md5
::::::::::::::
/root/scripts/app_data/root.zone
::::::::::::::
.        86400   IN      SOA bii-1.dnsv6lab.net. dnsv6lab.net.      2014102101 1800 900 604800 86400
;
.       3600000 IN      NS      bii-1.dnsv6lab.net.
bii-1.dnsv6lab.net.     IN      AAAA 240C:F:1:122::3
;
.       3600000 IN      NS      bii-2.dnsv6lab.net.
bii-2.dnsv6lab.net.     IN      AAAA 240C:F:1:122::6

arpa.       3600000 IN      NS       bii-2.dnsv6lab.net.
arpa.       3600000 IN      NS       bii-2.dnsv6lab.net.



3、Generate root, ARPA ZSK and KSK

# sh /root/scripts/gen_key.sh



4、Generate  root zone, ARPA. Zone

#sh /root/scripts/gen_root.sh












