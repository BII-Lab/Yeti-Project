#!/bin/sh
#
script_path=`dirname $0`

#
# this script is to check the root servers of Yeti Project
# - generate zones corresponding to each root server
# - genenate fragment of bind configuration file

# load setting
if [ -s ${script_path}/setting.sh ]; then
	. ${script_path}/setting.sh
else
	echo "Error: can not load gen root functions" 
	exit 1
fi

conf="$ROOT_ZONE_PATH/named.conf.zones"
date=`date`
serial=`date +"%Y%m%d00"`
ttl=518400

echo "# automatically genearted at $date"		> $conf
echo "#"						>> $conf
echo "#"						>> $conf
echo "# include this file in named.conf"		>> $conf
echo "# such as include \"zone/named.conf.zones\";"	>> $conf
echo "#"						>> $conf

for ns in `$dig +short +norec @::1 . ns`
do
	fname=`echo $ns | sed -e s/\.$//`
	echo "zone \"$fname\" {"			>> $conf
	echo "	type master;"				>> $conf
	fname="$ROOT_ZONE_PATH/$fname"
	echo "	file \"$fname\";"			>> $conf
	echo "};"					>> $conf
	echo ""						>> $conf

	echo "; automatically generated at $date"		> $fname
	echo ""							>> $fname
	echo "\$TTL $ttl"					>> $fname
	echo "@ IN SOA $ns hostmaster.$ns $serial 1800 900 604800 86400" \
								>> $fname
	echo "  IN NS  $ns"					>> $fname
	echo ""							>> $fname
	for addr in `dig $ns aaaa +short`
	do
		echo "  IN AAAA $addr"				>> $fname
	done
	echo ""							>> $fname
	echo "; fin"						>> $fname
done
echo "# fin"						>> $conf

$rndc reload
