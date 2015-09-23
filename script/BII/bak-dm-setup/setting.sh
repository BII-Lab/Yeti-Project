#
# zone file path for bind9, please change to you zone file dir
ROOT_ZONE_PATH=/YOURPATHTOZONEFILES/zone

# admin mail address
ADMIN_MAIL="USERNAME@YOURDOMAIN"

#####################################################################
# DO NOT REWRITE THE FOLLOWING LINES

if [ $ROOT_ZONE_PATH = "/YOURPATHTOZONEFILES/zone" ]; then
  echo "You must rewrite ROOT_ZONE_PATH in setting.sh"
  exit
fi
if [ $ADMIN_MAIL = "USERNAME@YOURDOMAIN" ]; then
  echo "You must rewrite ADMIN_MAIL in setting.sh"
  exit
fi

#
[ ! -d ${ROOT_ZONE_PATH} ] && mkdir -p ${ROOT_ZONE_PATH}

# key dir for bind9
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
os=`uname -v`
case $os in
  Linux*)
    sed="/bin/sed"
    dnssecsignzone="/usr/local/sbin/dnssec-signzone"
    rndc="/usr/local/sbin/rndc"
    dig="/usr/local/bin/dig"
    ;;
  NetBSD?6*)
    sed="/usr/pkg/bin/gsed"
    dnssecsignzone="/usr/pkg/sbin/dnssec-signzone"
    rndc="/usr/pkg/sbin/rndc"
    dig="/usr/pkg/bin/dig"
    ;;
  NetBSD?7*)
    sed="/usr/bin/sed"
    dnssecsignzone="/usr/pkg/sbin/dnssec-signzone"
    rndc="/usr/pkg/sbin/rndc"
    dig="/usr/pkg/bin/dig"
    ;;
  FreeBSD*)
    sed ="/usr/bin/sed"
    dnssecsignzone="/usr/local/sbin/dnssec-signzone"
    rndc="/usr/local/sbin/rndc"
    dig="/usr/local/bin/dig"
    ;;
  *)
    sed="/bin/sed"
    dnssecsignzone="/usr/local/sbin/dnssec-signzone"
    rndc="/usr/local/sbin/rndc"
    dig="/usr/local/bin/dig"
    ;;
esac

if [ ! -f $sed ]; then
  echo "$sed not exists"
  exit
fi

if [ ! -f $dnssecsignzone ]; then
  echo "$dnssecsignzone not exists"
  exit
fi

if [ ! -f $rndc ]; then
  echo "$rndc not exists"
  exit
fi

if [ ! -f $dig ]; then
  echo "$dig not exists"
  exit
fi
