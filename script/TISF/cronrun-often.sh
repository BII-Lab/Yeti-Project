#!/bin/sh

PATH=/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin
export PATH

cd /home/vixie/work/yeti-dm || exit 1

yeticonf_dm="/home/vixie/work/yeticonf/dm"
(cd $yeticonf_dm; git pull) 2>&1 | grep -v 'Already up-to-date.'

#
# first, fetch the iana zone, and stop if it's broken or unchanged
#
dig @192.5.5.241 +onesoa +nocmd +nocomments +nostats . axfr > iana-root.dns.new
if dnssec-verify -o . iana-root.dns.new > dnssec-verify.out 2>&1; then
	:
else
	cat dnssec-verify.out
	exit 1
fi
if [ ! -s iana-root.dns.new ]; then
	echo 'zero length or missing zone file from iana?' >&2
	exit 1
fi
reality=$(awk '$3 = "SOA" { print $7; exit }' iana-root.dns.new)
policy=$(cat $yeticonf_dm/iana-start-serial.txt)
if [ $reality -lt $policy ]; then
	exit 0
fi
if [ -e iana-root.dns ]; then
	if cmp -s iana-root.dns.new iana-root.dns; then
		exit 0
	fi
	mv iana-root.dns iana-root.dns.old
fi
mv iana-root.dns.new iana-root.dns

#
# second, create the yeti zone based on the iana zone, and sign it
#
keys=$(perl scripts/yeti-mkdns.pl)
if $? -ne 0; then
	echo yeti-mkdns failed
	exit 1
fi

if dnssec-signzone -Q -R -o . yeti-root.dns $keys > dnssec-signzone.out 2>&1
then
	:
else
	cat dnssec-signzone.out
	exit 1
fi
rndc -s yeti-dm reload . 2>&1 | grep -v 'zone reload up-to-date'

#
# third, remake the conf-include file (allow-transfer, also-notify)
#
if perl scripts/yeti-mkinc.pl; then
	:
else
	echo yeti-mkinc failed
	exit 1
fi
rndc -s yeti-dm reconfig

exit
