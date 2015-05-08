#
# zone file path for bind9, please change to you zone file dir
ROOT_ZONE_PATH=/pang/dns/named/zone
[ ! -d ${ROOT_ZONE_PATH} ] && mkdir -p ${ROOT_ZONE_PATH}

# admin mail
ADMIN_MAIL="ggpang@biigroup.cn"

# key dir for bind9
arpakeydir=$script_path/keys/arpa
[ ! -d $arpakeydir ] && mkdir -p $arpakeydir
rootkeydir=$script_path/keys/root
[ ! -d $rootkeydir ] && mkdir -p $rootkeydir
 
#
zonedir=$script_path/zone_data
[ ! -d $zonedir ] && mkdir $zonedir

origin_data=$script_path/ori_data
[ ! -d ${origin_data} ] && mkdir $origin_data

tmp_data=$script_path/tmp_data
[ ! -d ${tmp_data} ] && mkdir $tmp_data

app_data=$script_path/app_data
[ ! -d ${app_data} ] && mkdir $app_data

zone_data=$script_path/zone_data
[ ! -d ${zone_data} ] &&  mkdir $zone_data
ns_file=$script_path/app_data/ns.sh
[ ! -s $ns_file ] &&  echo "please create ns.sh of root ns servers message"

#check os
os=`uname`
if [ $os = "Linux" ]; then
       sed="/bin/sed"
       dnssecsignzone="/usr/local/sbin/dnssec-signzone"
elif [ $os = "NetBSD" ]; then
       sed="/usr/pkg/bin/gsed"
       dnssecsignzone="/usr/pkg/sbin/dnssec-signzone"
elif [ $os = "FreeBSD" ];then
       sed ="/usr/bin/sed"
      dnssecsignzone="/usr/local/sbin/dnssec-signzone"
else
       sed="/bin/sed"
       dnssecsignzone="/usr/local/sbin/dnssec-signzone"
fi

if [ ! -f $sed ]; then
       echo "$sed not exists"
       exit
fi

if [ ! -f $dnssecsignzone ]; then
       echo "$dnssecsignzone not exists"
       exit
fi
