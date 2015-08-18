#!/bin/sh

# Capture packets on time-limited files

# For discussion of the choice of pcapdump, see the file doc/Capture.md

# binaries needed, change accordingly

# pcapdump is at https://packages.debian.org/sid/pcaputils You *need*
# the patch in
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=545985
PCAPDUMP="/usr/local/bin/pcapdump"
IFCONFIG="/sbin/ifconfig"
NTPDATE="/usr/sbin/ntpdate"
BC="/bin/bc"

# Interfaces to capture packets
# if you want to specify more than one, separate by spaces
# EXAMPLE
# IFACES="em0 em1"
# **CHANGE THIS** accordingly
#IFACES="em0 em1"
IFACES=""

# ** Destinations **
# If you want to select traffic directed to a specific address
# add it here
DESTINATIONS=""

# Want queries only?
# if you only want queries *AND* responses, switch it to "no"
QUERIES_ONLY="yes"

# Want v6 traffic?
DO_V6="yes"

# Want TCP traffic?
DO_TCP="yes"

# Want IP fragments?
DO_FRAGS="yes"

# Exclude patterns
NO_PAT=""

# ** Interval **
# This value defines the amount of seconds each pcap file will contain.
# We suggest 10-minutes files (600 seconds), but you can change it if
# you receive a lot of traffic
INTERVAL=""

# Start and Stop time
# The collection process will work within this time-window.  If the
# start_time is in the future, will sleep until it's time to work.
# The collection won't go beyond STOP_T if it's given.

# NOTE: The start and stop times are interpreted as UTC.  Do not
# convert them to your local time zone.
#
#START_T='2010-04-13 13:00:00'
#STOP_T='2010-04-16 00:00:00'

# Program to run to handle a file
# Each time a INTERVAL is completed, will execute this code
#KICK_CMD="./pcap-submit-to-oarc.sh"
#KICK_CMD="sh data-commit.sh $SAVEDIR"

# Unique name of the node where data is being collected.
# Please make sure that no two instances of pcapdump use the
# same NODENAME!
#if [ `uname` = "Linux" ]; then
#    NODENAME=`hostname --fqdn` 
#else
    NODENAME=`hostname`
#fi

# You can set SAVEDIR to a directory with lots of free space
# where the pcap files will be staged or stored
SAVEDIR=""

KICK_CMD=""
#
# End of configurable options
#

# Read local definitions if there is any
# You can use this file to set your own values without modifying this
# script
if [ -s settings.sh ]; then
    . ./settings.sh $SAVEDIR
fi


# Command line construction for pcapdump
set -- -t "${INTERVAL}" -w "${SAVEDIR}/${NODENAME}" -m qun
if [ ! -z "${START_T}" ]; then
    set -- "$@" -B "${START_T}"
fi
if [ ! -z "${STOP_T}" ]; then
    set -- "$@" -E "${STOP_T}"
fi
if [ ! -z "${KICK_CMD}" ]; then
    set -- "$@" -k "${KICK_CMD}"
fi

# Validate the programs I'm expecting to use
for prog in ${PCAPDUMP} ${IFCONFIG} ${NTPDATE} ${BC}; do
if [ ! -x ${prog} ] ; then
    echo "${prog} is not executable, aborting!"
    exit 1
fi
done

if [ ! -d ${SAVEDIR} ]; then
    mkdir -p ${SAVEDIR} 
fi

# Check if this script is running as root
if test -z "$UID" ; then
	UID=`id -u`
fi
if [ "${UID}" != "0" ]; then
    echo "Must run as root!"
    exit 1
fi
echo "Passed running-as-root check"

# Check if the IFACES values are valid
for IFACE in ${IFACES}; do
    IFACE_CHECK=`${IFCONFIG} ${IFACE}`
    if [ $? != "0" ]; then
        echo "Interface ${IFACE} checking failed!"
        echo "${IFACE_CHECK}"
        exit 1
    fi
    set -- "$@" -i "${IFACE}"
done
echo "Passed interface checks"

# Check INTERVAL is a number
echo $INTERVAL | egrep '^[0-9]+$' >/dev/null 2>&1
if [ $? != "0" ]; then
    echo "The interval ${INTERVAL} given is not a number, aborting"
    exit 1
fi

# NTP Check
# Verifies if the clocks are properly synchronized
NTP_CHECK=`${NTPDATE} -q clock.isc.org`
if [ $? != "0" ]; then
    echo "NTP check failed!"
    echo $NTP_CHECK
    exit 1
fi
# Now verify if offset is lower than certain threshold
NTP_OFFSET=`echo $NTP_CHECK | grep offset | head -1 | cut -d, -f3 | cut -d' ' -f3`
# Shell don't do float arithmetic, so we use bc for comparison
OFFSET_THRESHOLD="0.5"
if [ $(echo "${NTP_OFFSET} > ${OFFSET_THRESHOLD}" | bc) -eq 1 ]; then
    echo "Your clock is skewed by ${NTP_OFFSET} seconds!"
    echo "We suggest a clock sync, Aborting"
    exit 1
fi
echo "Passed NTP check"


# Build some of the command line options

BPF_filter="port 53"

# Check the list of destinations
if [ ! -z ${DESTINATIONS} ]; then
    echo "Capturing only for ${DESTINATIONS}"
    BPF_filter="${BPF_filter} and ("
    for DEST in ${DESTINATIONS}; do
        BFP_filter="${BPF_filter} or dst host ${DEST} "
    done
    BPF_filter="${BPF_filter})"
fi

if [ "${QUERIES_ONLY}" != "" ]; then
    echo "Ignoring option QUERIES_ONLY=${QUERIES_ONLY} (unsupported)"
fi

# Include v6 traffic?
if [ "${DO_V6}" = "yes" ]; then
    echo "Capturing IPv6"
    BPF_filter="${BPF_filter} and (ip or ip6)"
else
    echo "Not capturing IPv6"
    BPF_filter="${BPF_filter} and ip"
fi

# Include TCP traffic?
if [ "${DO_TCP}" = "yes" ]; then
    echo "Capturing TCP"
    BPF_filter="${BPF_filter} and (tcp or udp)"
else
    echo "Not capturing TCP"
    BPF_filter="${BPF_filter} and udp"
fi

# Include IP fragments?
if [ "${DO_FRAGS}" = "yes" ]; then
    echo "Ignoring option DO_FRAGS (unsupported)"
fi

# Exclude Patterns
if [ ! -z ${NO_PAT} ]; then
    echo "Ignoring option NO_PAT=${NO_PAT} (unsupported)"
fi

CMD="${PCAPDUMP} -f ${BPF_filter}"
echo "Executing '${CMD}'"
${PCAPDUMP} "$@" &
