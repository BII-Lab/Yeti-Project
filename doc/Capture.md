# DNS Message Capture

Since Yeti is a scientific research project, it needs to capture
DNS traffic sent for later analysis.

Today this is done using
[dnscap](https://www.dns-oarc.net/tools/dnscap), which is a
DNS-specific tool to produce pcap files. There are several versions of dnscap floating around, some people use the [Verisign one](https://github.com/verisign/dnscap) 

The script for this is `script/monitor-external/capture-dnscap.sh`.

Since dnscap loses packets in some cases (tested on a Linux kernel), some people use [pcapdump](https://packages.debian.org/sid/pcaputils). It requires [the patch attached to this bug report](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=545985)

# Packets vs. Messages

While usually a DNS message fits into a single IP packet, it is not
always true.

Sometimes an IPv6 UDP packet is fragmented and needs to be
reassembled. If this assembly does not complete we will still see
these fragments in dnscap output.

Sometimes DNS uses TCP. In these cases dnscap filters may not work,
and so dnscap may record traffic that it is not supposed to. For Yeti
this is not a problem, since we actually want to see all traffic.

# Future Directions

We may switch to an alternate data capture technology in the future,
such as [dnstap](http://dnstap.info/). This is a server-based DNS
message capure technology though, and is not currently supported out
of the box in any authoritative DNS servers.

