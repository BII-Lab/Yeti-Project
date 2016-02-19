2016-02-18
----
We observe that the packet size has already increased to more than
1280 bytes, which means that most DNS servers will fragment the
responses. We observe this in practice:

    09:50:07.183524 IP6 2001:470:78c8:2:224:9bff:fe13:3a9c.44664 > 240c:f:1:22::6.53: 19840+ [1au] DNSKEY? . (28)
    09:50:07.485850 IP6 240c:f:1:22::6 > 2001:470:78c8:2:224:9bff:fe13:3a9c: frag (0|1232) 53 > 44664: 19840*- 8/0/1 DNSKEY, DNSKEY, DNSKEY, DNSKEY, DNSKEY, DNSKEY, RRSIG, RRSIG[|domain]
    09:50:07.485850 IP6 240c:f:1:22::6 > 2001:470:78c8:2:224:9bff:fe13:3a9c: frag (1232|258)

`tcpdump` with a "port 53" filter does not see these fragments.

We notice that one of the DM (TISF) is using two RRSIG for the DNSKEY
RRset. We will ask them to fix it.

The RIPE Atlas measurements did not have the DO bit set when created.
A new set was created, and the old ones are still available.

2016-02-19
----
After add we added the sixth ZSK, we found that query DNSKEY on
`yeti.aquaray.com` via UDP failed:

    $ dig . @yeti.aquaray.com -t dnskey +dnssec 

TCP for the server worked:

    $ dig . @yeti.aquaray.com -t dnskey +dnssec +tcp

Smaller UDP queries worked too:

    $ dig . @yeti.aquaray.com -t ns +dnssec +tcp

This was reported on the Yeti list, and fixed shortly after:

http://lists.yeti-dns.org/pipermail/discuss/2016-February/000393.html

The underlying cause was the issue documented here:

https://github.com/torvalds/linux/commit/efb6de9b4ba0092b2c55f6a52d16294a8a698edd

