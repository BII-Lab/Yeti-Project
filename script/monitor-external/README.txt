# readme
#
# scripts from dns-orac ditl-tools
#
# capture DNS packet on DNS servers and save as pcap file, then send to our
# storage server
#
#

1. capture-dnscap.sh
     capture DNS packet with dnscap <https://github.com/verisign/dnscap>
[Alternative to the previous one]
1bis. capture-pcapdump.sh
     capture DNS packet with pcapdump
     <https://packages.debian.org/sid/pcaputils> You *need* the patch
     in <https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=545985>
     
2. data-commit.sh
    submit DNS packet via ssh
    
    notice: use ssh PubkeyAuthentication, so user should provide ssh public key

collector info：
server：data.dnsv6lab.net
user：yeti

3. settings.sh
   config option for dnscap/pcapdump 
   such as capture interval, ethernet interface, tcp support, fragment and so on

4. run
    sh capture-dnscap.sh

note:
    on ubuntu 14.04.2(kernel 4.0.7), dnscap works well.
    on Centos 6(kernel 2.6.32.*), dnscap works well.
    on FreeBSD 10.0, dnscap works well.
	
    linux kernel below 3.19, dnscap sometimes lost packets.
