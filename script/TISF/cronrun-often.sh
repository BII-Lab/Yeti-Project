#!/bin/sh

PATH=/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin
export PATH

cd /home/vixie/work/yeti-dm || exit 1

yeticonf_dm="/home/vixie/work/yeticonf/dm"
(cd $yeticonf_dm; git pull) 2>&1 | grep -v 'Already up-to-date.'

# this is F-root
iana_server="2001:500:2f::f"

#
# first, fetch the iana zone, and rebuild yeti zone if possible and indicated
#
dig @$iana_server +onesoa +nocmd +nocomments +nostats . axfr > iana-root.dns
if dnssec-verify -o . iana-root.dns > dnssec-verify.out 2>&1; then
	:
else
	cat dnssec-verify.out
	traceroute6 -q1 $iana_server
	exit 1
fi
if [ ! -s iana-root.dns ]; then
	echo 'zero length or missing zone file from iana?' >&2
	exit 1
fi
reality=$(awk '$3 = "SOA" { print $7; exit }' iana-root.dns)
policy=$(cat $yeticonf_dm/ns/iana-start-serial.txt)
new_zone=0
if [ $reality -ge $policy ]; then
	new_zone=1
	if [ -e iana-root.dns.old ]; then
		if cmp -s iana-root.dns iana-root.dns.old; then
			new_zone=0
		fi
	fi
	if [ $new_zone -ne 0 ]; then
		rm -f iana-root.dns.old
		cp iana-root.dns iana-root.dns.old
	fi
fi

#
# second, remake the conf-include file (allow-transfer, also-notify)
#
new_inc=0
if [ $reality -ge $policy ]; then
	new_inc=1
	if perl scripts/yeti-mkinc.pl; then
		:
	else
		echo 'yeti-mkinc failed' >&2
		exit 1
	fi
	if [ -e named.yeti.inc.old ]; then
		if cmp -s named.yeti.inc named.yeti.inc.old; then
			new_inc=0
		fi
	fi
	if [ $new_inc -ne 0 ]; then
		rndc -s yeti-dm reconfig
		rm -f named.yeti.inc.old
		cp named.yeti.inc named.yeti.inc.old
	fi
fi

#
# third, if new zone, create the yeti zone based on the iana zone, and sign it
#
if [ $new_zone -ne 0 ]; then
	keys=$(perl scripts/yeti-mkdns.pl)
	if [ $? -ne 0 ]; then
		echo 'yeti-mkdns failed' >&2
		exit 1
	fi

	if dnssec-signzone -Q -R -o . -x yeti-root.dns $keys \
		> dnssec-signzone.out 2>&1
	then
		rndc -s yeti-dm reload . 2>&1 \
			| grep -v 'zone reload up-to-date'
	else
		cat dnssec-signzone.out
		exit 1
	fi
fi

exit
