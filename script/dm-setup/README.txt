
0. system and bind9
     Linux,NetBSD
     bind-9.10.2
1.add the execute permissions
    chmod +x  *.sh

2. root and arpa zone config
    edit app_data/ns.sh
    configure root zone params
    configure  root  nameservers

3. script params settings
  #vi setting.sh


4.get ZSK/KSK from bii and save to dir keys , and run the following script(Generate a new zone, resign the zone, reload bind9)

   #sh /path/to/gen_root.sh autoupdate

5.Add plans to task for the daily update regularly
 
  eg:
   #echo "10  13  *  *  *   root sh /path/to/gen_root.sh  autoupdate >/dev/null 2>&1" >> /etc/crontab


6.According to the time the key parameters,Setup script execution time.
  eg:
  #echo "01  02 *  *  *  root sh /path/to/update_soa_resign_zone.sh >/dev/null 2>&1" >> /etc/crontab

