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
confnew="$ROOT_ZONE_PATH/named.conf.zones.new"
date=`date`
serial=`date +"%Y%m%d00"`
ttl=518400

cnt=3
while [ $cnt -gt 0 ]; do
	$dig +short +norec @::1 . ns | sort > ns_list.new
	if [ -s ns_list.new ]; then
		break;
	fi
	cnt=`expr $cnt - 1`
done
if [ ! -s ns_list.new ]; then
	echo "ns list zero"
	exit
fi
if [ -f ns_list ]; then
	cmp ns_list ns_list.new >/dev/null
	if [ $? -eq 0 ]; then
		rm -f ns_list.new
		exit
	fi
fi

rm -f ns_list
mv ns_list.new ns_list

error=0

echo "# automatically genearted at $date"		>  $confnew
echo "#"						>> $confnew
echo "#"						>> $confnew
echo "# include this file in named.conf"		>> $confnew
echo "# such as include \"zone/named.conf.zones\";"	>> $confnew
echo "#"						>> $confnew

for ns in `cat ns_list`
do
	cnt=0

	fname=`echo $ns | sed -e s/\.$//`
	echo "zone \"$fname\" {"			>> $confnew
	echo "	type master;"				>> $confnew

	fname="$ROOT_ZONE_PATH/$fname"
	echo "	file \"$fname\";"			>> $confnew
	echo "};"					>> $confnew
	echo ""						>> $confnew

	fnamenew="$fname.new"

	echo "; automatically generated at $date"		>  $fnamenew
	echo ""							>> $fnamenew
	echo "\$TTL $ttl"					>> $fnamenew
	echo "@ IN SOA $ns hostmaster.$ns $serial 1800 900 604800 86400" \
								>> $fnamenew
	echo "  IN NS  $ns"					>> $fnamenew
	echo ""							>> $fnamenew
	for addr in `dig $ns aaaa +short`
	do
		echo "  IN AAAA $addr"				>> $fnamenew
		cnt=`expr $cnt + 1`
	done
	echo ""							>> $fnamenew
	echo "; fin"						>> $fnamenew
	if [ $cnt -eq 0 ]; then
		error=1
	fi
	if [ ! -s $fnamenew ]; then
		error=2
	fi
	if [ $error -eq 0 ]; then
		rm -f $fname
		mv $fnamenew $fname
	fi
done
echo "# fin"						>> $confnew

if [ $error -eq 0 ]; then
	rm -f $conf
	mv $confnew $conf
	$rndc reload
fi

