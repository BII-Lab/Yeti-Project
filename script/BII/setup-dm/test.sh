#!/bin/sh

# load functions
workdir=`dirname $0`
if [ -s $workdir/setup-dm-functions.sh ];then
	 . $workdir/setup-dm-functions.sh 
else
	echo "`$datetime` setup-dm-functions.sh is't exsit" >> $logfile
    exit 1
fi

echo "++++++++++++workdir is $workdir"


case "$1" in
    refresh)
         echo "befor pull" `pwd`
         refresh_git_repository
         echo "after pull" `pwd`
         ;;
    download)
        
        root_zone_download
        check_root_zone
        ;;
    genzone)
        generate_root_ns_file
        generate_root_zone
        ;;
    signzone)
        get_latest_dnskey
        sign_root_zone
        ;;
    full)

        refresh_git_repository
        root_zone_download
        check_root_zone

        generate_root_ns_file
        generate_root_zone

        get_latest_dnskey
        sign_root_zone
        ;;
    *)
     echo "Usage $0 download|genzone|signzone|full"
     exit 1
     ;;
esac

#reload_root_zone
