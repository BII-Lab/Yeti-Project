Guide to set up Distribution Master(DM) 

Operation System：Linux/NetBSD

1. Set up ntp time synchronization, configure firewall(bind9/email) 
2. Set up sendmail/postfix service for email alarm 
3. Set up bind-9.10.2 wich ECC support 
4. Configure named.conf and enable rndc control tool 
5. download setup script 
   git clone  https://github.com/BII-Lab/Yeti-Project.git 
   cd Yeti_project/script/dm-setup
6、modify configure file app_data/ns.sh and setting.sh
    configure root zone params
    configure  root  nameservers

7. get root and arpa’s KSK/ZSK from BII
Notice: 
1) The algorithm to generate ZSK KSK：RSASHA256 
2) Length of ZSK：1024, TTL: 2 weeks 
3) Length of KSK：2048, TTL: 3months 

8. sign root zone and reload bind9
# sh /path/to/gen_root.sh autoupdate 

*Notice： 
1) Way to roll the key: manual + scripts 
2) Require administrator add update_soa_resign_zone.sh to task plan at least two days before. 

9. Add plans in crontab 
(1)run resigning script everyday 
sh /path/to/gen_root.sh autoupdate ---- Update root.zone, arpa.zone; sign root.zone and arpa.zone; reload named

(2)add time task key rollover 
sh /path/to/update_soa_resign_zone.sh ----- update soa && resigning; run two days before ZSK/KSK inactive 


Commands be involved in shell scripts 
    named,rndc,dnssec-keygen, dnssec-signzone, awk,bc, git, mail, logger, ntp 
