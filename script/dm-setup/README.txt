1.add the execute permissions
    chmod +x  *.sh

2. update root NS record
    edit app_data/ns.sh
    configure root zone params
    add NS record:
       root_NS_num=x.xx.xx
       NSnum_addr=2401::8
    eg:
      root_NS_2=bii.dns-lab.net.
      NS2_addr=2401::8

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

TODO
1. ns.sh 
     rename options 
