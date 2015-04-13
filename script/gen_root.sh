#!/bin/sh
ori_data=/root/scripts/ori_data
tmp_data=/root/scripts/tmp_data
app_data=/root/scripts/app_data
zone_data=/root/scripts/zone_data
#signzone=`which dnssec-signzone`

arpakeydir=/root/scripts/key/arpa
rootkeydir=/root/scripts/key/root
zonedir="/root/scripts/zone_data"
#rndccom=`which rndc`

################################################ download root\arpa files#########################################################################

zone_download () {
                  rm -f $ori_data/*              
                  wget -i $app_data/wwwdownload.txt -P $ori_data  > /dev/null 2>&1 
          
                  if [ $? -ne 0 ]
           
                       then 
                           rm -f $ori_data/*

                           wget -i $app_data/ftpdownload.txt  -P $ori_data  >/dev/null 2>&1
                             
                           if [ $? -ne 0 ] 
                              then 
                                   rm -f $ori_data/*
                                   wget -i $app_data/wwwdownload.txt -P $ori_data  >/dev/null   2>&1
                                   
                                    if [ $? -ne 0 ]
                                        then
                                        echo " The zonefile download failed" |mail -s "zonedownload failed" ggpang@biigroup.cn  >/dev/null 2>&1
                                        exit
                                    fi
                           fi
                   fi
                          
         
                         
}


############################## check arap.zone/ root.zone ###############################################################################################

check_zone() {  

             arpanum1=`md5sum $ori_data/arpa.zone.gz |awk '{print $1}'`
             arpanum2=`cat $ori_data/arpa.zone.gz.md5`


       if   [ $arpanum1 = $arpanum2 ] 
          
             then
        
                 echo "arpa.zone is ok"
                 [ -f $ori_data/arpa.zone.gz ] &&  gzip -d $ori_data/arpa.zone.gz
                 cp $ori_data/arpa.zone  $zone_data/arpa.zone
       else
                 echo "Warning: This"arpa.zone" file is incorrect Please check."
       fi   





             rootnum1=`md5sum $ori_data/root.zone.gz |awk '{print $1}'`
             rootnum2=`cat $ori_data/root.zone.gz.md5`

             if   [ $rootnum1 = $rootnum2 ] 
            
                   then
                        echo "root.zone is ok"
                        [ -f $ori_data/root.zone.gz   ] && gzip -d $ori_data/root.zone.gz
                        cp $ori_data/root.zone $zone_data/root.zone

             else
                       echo "Warning: This "root-server.net.zone" file is incorrect Please check."
             fi


}




#######Modify the root zone files conform to the requirements of the test###########################################################################

 root_num_1=`head -n 1 $ori_data/root.zone|awk '{print $7}'`
 root_num_2=`head -n 1 $app_data/root.zone |awk '{print $7}'`

gen_root () {

          grep -v "NSEC" $ori_data/root.zone  |grep -v "RRSIG" | grep -v "DNSKEY"|  grep -v "SOA"  > $tmp_data/root.zone-1
          
          
         grep -Ev 'a.root-servers.net.|b.root-servers.net.|c.root-servers.net.|d.root-servers.net.|e.root-servers.net.|f.root-servers.net.|g.root-servers.net.|
h.root-servers.net.|i.root-servers.net.|j.root-servers.net.|k.root-servers.net.|l.root-servers.net.|m.root-servers.net.' $tmp_data/root.zone-1  >$tmp_data/root
.zone-2

          cp $app_data/root.zone $zone_data/root.zone

          sed -i "s/`echo ${root_num_2}`/`echo ${root_num_1}`/g" $zone_data/root.zone 
          sleep 5
          cat $tmp_data/root.zone-2 >> $zone_data/root.zone
}



##########Modify the arpa zone files conform to the requirements of the test###########################################################################

gen_arpa_zone() {
          

         arpa_num_1=`head -n 1 $ori_data/arpa.zone |awk '{print $7}'`
         arpa_num_2=`head -n 1 $app_data/arpa.zone |awk '{print $7}'`


         egrep -v "NSEC|RRSIG|DNSKEY|SOA" $ori_data/arpa.zone > $tmp_data/arpa.zone-1
         egrep -v  [a-m].root-servers.net $tmp_data/arpa.zone-1  > $tmp_data/arpa.zone-2
         
         
         sed -i "s/${arpa_num_2}/${arpa_num_1}/g"  $app_data/arpa.zone
         cp $app_data/arpa.zone  $zone_data/arpa.zone
         cat $tmp_data/arpa.zone-2 >> $zone_data/arpa.zone


}

##############################################sign  zone############################################################

sig_zone() {

         /usr/local/sbin/dnssec-signzone  -K $rootkeydir  -o .      -S -x   $zonedir/root.zone
         
         /usr/local/sbin/dnssec-signzone  -K  $arpakeydir  -o arpa.  -S -x  $zonedir/arpa.zone
}


#############################################reload  bind############################################################
reload_bind() {
         /bin/cp -f  $zonedir/root.zone.signed  /home/dns/named/zone/
         /bin/cp -f  $zonedir/arpa.zone.signed  /home/dns/named/zone/

         /usr/local/sbin/rndc   reload
}


zone_download 
check_zone
gen_root
gen_arpa_zone
sig_zone
reload_bind
