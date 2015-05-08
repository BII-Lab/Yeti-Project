#!/bin/sh


script_path=`dirname $0`

# load functions
if [ -s ${script_path}/gen_root_functions.sh ]; then
        . ${script_path}/gen_root_functions.sh
else
        echo "Error: can not load gen root functions"  
        exit 1
fi

# main flow
case $1 in
  autoupdate)
    echo "$start_time" >> $logfile
    gen_root_arpa_file
    zone_download

    root_current_soa_serial=`$sed -n 2p $zone_data/root.zone |awk '{print $7}'`
    root_origin_soa_serial=`$sed -n 5p  $origin_data/root.zone|awk '{print $7}'`

    arpa_current_soa_serial=`$sed -n 1p $zone_data/arpa.zone |awk '{print $7}'`
    arpa_origin_soa_serial=`$sed -n 5p $origin_data/arpa.zone |awk '{print $7}'`
     
    if [ $arpa_origin_soa_serial -ge ${arpa_current_soa_serial:=0} ]; then
        gen_arpa_zone
        sign_arpa_zone
        reload_bind
    else
        echo "arpa zone file was not update !!!!"  >> $logfile
        
    fi

    if [ ${root_origin_soa_serial} -ge  ${root_current_soa_serial:=0}  ]; then
      gen_root_zone
      
      insert_arpa_ds
      sign_root_zone
      reload_bind
    else
      echo "root zone file was not update!!!" >> $logfile
    fi

    ;;
  manualupdate)
   
    gen_root_arpa_file
    zone_download

    root_current_soa_serial=`$sed -n 2p $zone_data/root.zone |awk '{print $7}'`
    root_origin_soa_serial=`$sed -n 5p  $origin_data/root.zone|awk '{print $7}'`

    arpa_current_soa_serial=`$sed -n 1p $zone_data/arpa.zone |awk '{print $7}'`
    arpa_origin_soa_serial=`$sed -n 5p $origin_data/arpa.zone |awk '{print $7}'`
    gen_root_zone
    gen_arpa_zone 
    sign_arpa_zone
    insert_arpa_ds
    sign_root_zone
    reload_bind
    ;;
  *)
    echo "sh gen_root.sh  autoupdate | manualupdate "
    ;;
esac
