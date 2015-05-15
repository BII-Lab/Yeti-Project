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
    echo "start $start_time" >> $logfile
    gen_root_arpa_file
    zone_download

    if [ -f $zone_data/root.zone ]; then
      root_current_soa_serial=`$sed -n 2p $zone_data/root.zone |awk '{print $7}'`
    else
      root_current_soa_serial=0
    fi
    root_origin_soa_serial=`$sed -n 5p  $origin_data/root.zone|awk '{print $7}'`

    if [ -f $zone_data/arpa.zone ]; then
      arpa_current_soa_serial=`$sed -n 1p $zone_data/arpa.zone |awk '{print $7}'`
    else
      arpa_current_soa_serial=0
    fi
    arpa_origin_soa_serial=`$sed -n 5p $origin_data/arpa.zone |awk '{print $7}'`
     
    if [ $arpa_origin_soa_serial -ge $arpa_current_soa_serial ]; then
        gen_arpa_zone
        sign_arpa_zone
    else
        echo "arpa zone file was not update !!!!"  >> $logfile
    fi

    if [ $root_origin_soa_serial -ge $root_current_soa_serial ]; then
      gen_root_zone
      insert_arpa_ds
      sign_root_zone
    else
      echo "root zone file was not update!!!" >> $logfile
    fi

    reload_bind
    sleep 2

    end_time=`date +%Y%m%d%H%M%S`
    root_soa=`$dig @::1 . soa +short | awk '{print $3}'`
    arpa_soa=`$dig @::1 arpa soa +short | awk '{print $3}'`
    echo "end $end_time root $root_soa apra $arpa_soa" >> $logfile
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
