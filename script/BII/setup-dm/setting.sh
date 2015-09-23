#
# settings for setup DM

servername=`hostname`
logfile="$workdir/log/setup-dm.log"

# bind9 must listen on this address
serveraddr="127.0.0.1"

# change to where the final root zone published  
root_zone_path="/dns/named/zone"

#email alert, must chang this
sender="xxxx@xxxx.xxx"
admin_mail="xxxx@xxx.com"

# must exist and should not change 
icann_ksk_file="$workdir/config/ksk.txt"
current_root_list="$workdir/config/yeti-root-servers.txt"

# should not change
iana_start_serial="$workdir/config/iana-start-serial.txt"

# git repo, should change to your git repo
git_repository_dir="/tmp/yeti-dm"
git_root_ns_list="$git_repository_dir/yeti-root-servers.txt"

# command depends
datetime="date +%Y-%m-%d-%H:%M:%S"
ldns_verify_zone=`which ldns-verify-zone`
parsednskey_command="$workdir/bin/parsednskey"

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

[ ! -d ${workdir}/log ] &&  mkdir -p ${workdir}/log

os=`uname`
case $os in
  Linux*)
    sed="/bin/sed"
    dnssecsignzone="/usr/local/sbin/dnssec-signzone"
    dnsseckeygen="/usr/local/sbin/dnssec-keygen"
    rndc="/usr/local/sbin/rndc"
    dig="/usr/local/bin/dig"
    wget="/usr/bin/wget"
    git="/usr/bin/git"
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
    sed="/bin/sed"
    dnssecsignzone="/usr/local/sbin/dnssec-signzone"
    dnsseckeygen="/usr/local/sbin/dnssec-keygen"
    rndc="/usr/local/sbin/rndc"
    dig="/usr/local/bin/dig"
    wget="/usr/local/bin/wget"
    git="/usr/local/bin/git"
    ;;
esac

# check depends
for program in $sed $dnssecsignzone $dnsseckeygen $rndc $dig $wget ${ldns_verify_zone} $git; do
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
