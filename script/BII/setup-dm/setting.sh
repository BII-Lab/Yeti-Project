#
# settings for setup DM

servername=$(hostname)

# bind9 must listen on this address
serveraddr="127.0.0.1"

# set to where the final root zone published  
root_zone_path="/home/dns/named/zone"

#genertate notfiy_list and zonetransfer_list 
named_notify_list="/etc/notify_list.conf"
named_zonetransfer_acl="/etc/zonetransfer_list.conf"

# log, email alert, must chang this
logfile="$workdir/log/setup-dm.log"
sender="xxxx@xxx.com"
admin_mail="admin@xxxx.com"

# must exist and have content
icann_ksk_file="$workdir/config/ksk.txt"
current_root_list="$workdir/config/yeti-root-servers.txt"

#
iana_start_serial="$workdir/config/iana-start-serial.txt"
key_start_serial_file="iana-start-serial.txt"

# git repo
git_repository_dir="/tmp/dmtest"
zsk_git_repository_dir="$git_repository_dir/zsk"
ksk_git_repository_dir="$git_repository_dir/ksk"
git_root_ns_list="$git_repository_dir/yeti-root-servers.yaml"

zsk_tag_file="zsk_tag.txt"
ksk_tag_file="ksk_tag.txt"

# command depends
datetime="date +%Y-%m-%d-%H:%M:%S"
ldns_verify_zone=$(which ldns-verify-zone)

python=$(which python)
# key dir for bind9
rootkeydir=$workdir/keys/root
[ ! -d $rootkeydir ] && mkdir -p $rootkeydir

origin_data=$workdir/origin
[ ! -d ${origin_data} ] && mkdir $origin_data

tmp_data=$workdir/tmp
[ ! -d ${tmp_data} ] && mkdir $tmp_data

config=$workdir/config

zone_data=$workdir/zone
[ ! -d ${zone_data} ] &&  mkdir $zone_data

os=$(uname)
case $os in
  Linux*)
    sed=$(which sed)
    dnssecsignzone=$(which dnssec-signzone)
    dnsseckeygen=$(which dnssec-keygen)
    rndc=$(which rndc)
    dig=$(which dig)
    wget=$(which wget)
    git=$(which git)
    ;;
  NetBSD?6*)
    sed="/usr/pkg/bin/gsed"
    dnssecsignzone="/usr/pkg/sbin/dnssec-signzone"
    dnsseckeygen="/usr/local/sbin/dnssec-keygen"   
    rndc="/usr/pkg/sbin/rndc"
    dig="/usr/pkg/bin/dig"
    wget="/usr/local/bin/wget"
    git="/usr/bin/git"
    ;;
  NetBSD?7*)
    sed="/usr/local/sbin/gsed"
    dnssecsignzone="/usr/pkg/sbin/dnssec-signzone"
    dnsseckeygen="/usr/local/sbin/dnssec-keygen"
    rndc="/usr/pkg/sbin/rndc"
    dig="/usr/pkg/bin/dig"
    wget="/usr/pkg/bin/wget"
    git="/usr/pkg/bin/git"
    ;;
  FreeBSD*)
    sed="/usr/local/sbin/gsed"
    dnssecsignzone="/usr/local/sbin/dnssec-signzone"
    dnsseckeygen="/usr/local/sbin/dnssec-keygen"
    rndc="/usr/local/sbin/rndc"
    dig="/usr/local/bin/dig"
    wget="/usr/local/bin/wget"
    git="/usr/local/bin/git"
    ;;
  *)
    sed=$(which sed)
    dnssecsignzone=$(which dnssec-signzone)
    dnsseckeygen=$(which dnssec-keygen)
    rndc=$(which rndc)
    dig=$(which dig)
    wget=$(which wget)
    ;;
esac

for program in $sed $dnssecsignzone $dnsseckeygen $rndc $dig $wget $python; do
    if [ ! -x $program ]; then
        command=`basename $program`
        if which $command; then
            echo "please set correct path for $command in the case ${os}"
            exit 1
        fi

        echo "$program not exists, please install $command"
        exit 1
    fi
done
