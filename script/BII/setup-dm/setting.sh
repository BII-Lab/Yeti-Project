# settings for setup DM

# server name
SERVER_NAME=$(hostname)

# bind9 must listen on this address
SERVER_ADDR="xx::xx"
F_SERVER="f.root-servers.net"

# genertate notfist and zonetransfer_list
BIND_CONF="/etc/named" 
[ ! -d $BIND_CONF ] && mkdir $BIND_CONF

# set to where the final root zone published  
BIND_ZONE_PATH="/path/to/named/zone"
NOTIFY_LIST="$BIND_CONF/notify_list.conf"
ZONETRANSFER_ACL="$BIND_CONF/zonetransfer_list.conf"
HINT="$WORKDIR/tmp/named.cache"

# log, email alert, must chang this
LOG_FILE="$WORKDIR/log/setup-dm.log"
SENDER="xxx@y.com"
ADMIN_MAIL="admin@y.com"

# configuration for DM setup
CONFIG=$WORKDIR/config
ICANN_KSK="$CONFIG/ksk.txt"
CURRENT_ROOT_LIST="$CONFIG/yeti-root-servers.txt"
START_SERIAL="iana-start-serial.txt"
IANA_START_SERIAL="$CONFIG/${START_SERIAL}"

# Yeti DM repository, please change this.
DM_REPO="/path/to/dmrepo"
ADMIN='Kevin Gong'
# three dm node are bii wide tisf 
DM='bii'
CHANGE="${DM_REPO}/CHANGES"

# public key dir
ZSK_DIR="$DM_REPO/zsk"
[ ! -d ${ZSK_DIR} ] && mkdir ${ZSK_DIR}

KSK_DIR="$DM_REPO/ksk"
[ ! -d ${KSK_DIR} ] && mkdir ${KSK_DIR}

ROOT_LIST="$DM_REPO/ns/yeti-root-servers.yaml"

# command depends
NOW="date +%Y-%m-%d-%H:%M:%S"
LDNS_VERIFY_ZONE=$(which ldns-verify-zone)
PERL=$(which perl)
PYTHON=$(which python)

# dir layout for DM setup
ROOT_KEY=$WORKDIR/keys/root
NEW_ZSK="${ROOT_KEY}/newkey/zsk"
NEW_KSK="${ROOT_KEY}/newkey/ksk"
ORIGIN_ZONE="$WORKDIR/origin"
TMP_ZONE="$WORKDIR/tmp"
LOG_DIR="$WORKDIR/log"
ZONE_DATA="$WORKDIR/zone"

# init dirs
ALL="$ROOT_KEY $NEW_ZSK $NEW_KSK $ORIGIN_ZONE $TMP_ZONE $LOG_DIR $ZONE_DATA"
for dir in ${ALL}; do
    [ ! -d ${dir} ] && mkdir -p ${dir}
done

OS=$(uname)
case $OS in
  Linux*)
    SED=$(which sed)
    DNSSECSIGNZONE=$(which dnssec-signzone)
    DNSSECKEYGEN=$(which dnssec-keygen)
    RNDC=$(which rndc)
    DIG=$(which dig)
    WGET=$(which wget)
    GIT=$(which git)
    PERL=$(which perl)
    ;;
  NetBSD?6*)
    SED="/usr/pkg/bin/gsed"
    DNSSECSIGNZONE="/usr/pkg/sbin/dnssec-signzone"
    DNSSECKEYGEN="/usr/local/sbin/dnssec-keygen"
    RNDC="/usr/pkg/sbin/rndc"
    DIG="/usr/pkg/bin/dig"
    WGET="/usr/local/bin/wget"
    GIT="/usr/bin/git"
    PERL="usr/bin/perl"
    ;;
  NetBSD?7*)
    SED="/usr/local/sbin/gsed"
    DNSSECSIGNZONE="/usr/pkg/sbin/dnssec-signzone"
    DNSSECKEYGEN="/usr/local/sbin/dnssec-keygen"
    RNDC="/usr/pkg/sbin/rndc"
    DIG="/usr/pkg/bin/dig"
    WGET="/usr/pkg/bin/wget"
    GIT="/usr/pkg/bin/git"
    PERL="usr/pkg/bin/perl"
    ;;
  FreeBSD*)
    SED="/usr/local/sbin/gsed"
    DNSSECSIGNZONE="/usr/local/sbin/dnssec-signzone"
    DNSSECKEYGEN="/usr/local/sbin/dnssec-keygen"
    RNDC="/usr/local/sbin/rndc"
    DIG="/usr/local/bin/dig"
    WGET="/usr/local/bin/wget"
    GIT="/usr/local/bin/git"
    PERL="/usr/local/bin/perl"
    ;;
  *)
    SED=$(which sed)
    DNSSECSIGNZONE=$(which dnssec-signzone)
    DNSSECKEYGEN=$(which dnssec-keygen)
    RNDC=$(which rndc)
    DIG=$(which dig)
    WGET=$(which wget)
    PERL=$(which perl)
    ;;
esac

# check program exist or not
for program in $SED $DNSSECSIGNZONE $DNSSECKEYGEN $RNDC $DIG $WGET $PYTHON; do
    if [ ! -x $program ]; then
        command=`basename $program`
        if which $command; then
            echo "please set correct path for $command in the case ${OS}"
            exit 1
        fi

        echo "$program not exists, please install $command"
        exit 1
    fi
done
