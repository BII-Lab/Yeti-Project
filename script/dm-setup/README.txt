1.add the execute permissions
    chmod +x  *.sh


2. Modify the following files in their own environment

    [root@localhost app_data]# ll
    0
    -rw-r--r-- 1 root root 225 5 4 14:18 arpa.zone
    -rw-r--r-- 1 root root 299 5 4 09:38 dns-lab.net.zone
    -rw-r--r-- 1 root root 182 5 4 09:38 ftpdownload.txt
    -rw-r--r-- 1 root root 380 5 4 09:38 root.zone
    -rw-r--r-- 1 root root 187 5 4 09:38 wwwdownload.txt

    [root@localhost app_data]# more arpa.zone
 
     arpa.                       86400   IN      SOA  ns1.dns-lab.net. yeti.biigroup.cn.     2015050301 1800 900 604800 86400
     arpa.      518400   IN      NS        ns1.dns-lab.net.
     arpa.      518400   IN      NS        ns2.dns-lab.net.
   
    [root@localhost app_data]# more  wwwdownload.txt

    http://www.internic.net/domain/arpa.zone.gz 
    http://www.internic.net/domain/arpa.zone.gz.md5 
    http://www.internic.net/domain/root.zone.gz 
    http://www.internic.net/domain/root.zone.gz.md5
    
    [root@localhost app_data]# more ftpdownload.txt 
     ftp://ftp.internic.net/domain/arpa.zone.gz
     ftp://ftp.internic.net/domain/arpa.zone.gz.md5 
     ftp://ftp.internic.net/domain/root.zone.gz 
     ftp://ftp.internic.net/domain/root.zone.gz.md5

   [root@localhost app_data]# more root.zone

    .        86400   IN      SOA ns1.dns-lab.net. yeti.biigroup.cn.      2014102101 1800 900 604800 86400
    .       518400  IN      NS      ns1.dns-lab.net.
    ns1.dns-lab.net. 3600000        IN      AAAA 240C:F:1:122::3
    .       518400  IN      NS      ns2.dns-lab.net.
    ns2.dns-lab.net. 3600000        IN      AAAA 240C:F:1:122::6

    arpa.       518400  IN      NS       ns2.dns-lab.net.
    arpa.       518400  IN      NS       ns2.dns-lab.net.


3.Modify the configuration files of the script parameters and variables
  #vi setting.sh


4.get ZSK/KSK from bii and save to dir keys , and run the following script(Generate a new zone, zone resign the zone, named loading process)

   #sh /path/to/gen_root.sh autoupdate

5.Add plans to task for the daily update regularly
 
  eg:
   #echo "10  13  *  *  *   root sh /path/to/gen_root.sh  autoupdate >/dev/null 2>&1" >> /etc/crontab


6.According to the time the key parameters,Setup script execution time.
  eg:
  #echo "01  02 *  *  *  root sh /path/to/update_soa_resign_zone.sh >/dev/null 2>&1" >> /etc/crontab

