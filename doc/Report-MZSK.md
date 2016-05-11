Yeti Project Report: Multi-ZSK Experiment (MZSK)
            Version: 1.0
               Date: 2016-05-11

Introduction
============
Yeti DNS System is a live testbed for Root DNS Server System:

    https://yeti-dns.org/

In early 2016, the Yeti Project ran an experiment to test whether the
Yeti root could be operated using more than a single Zone-Signing Key
(ZSK). This was known as the Multi-ZSK Experiment (MZSK).
 
Yeti has three distribution masters (DM), which take the IANA root
zone and modify it so that it can be used by the Yeti root servers.
They also publish this modified zone to those Yeti root servers. This
setup is documented in Yeti-DM-Setup[1].

DNSSEC uses a Key-Signing Key (KSK), which in turn signs one or more
Zone-Signing Keys (ZSK), which in turn sign the zone. In the IANA
setup it looks something like this:

   +-----------+          +--------------+         +-----------+
   | ICANN KSK |--------->| Verisign ZSK |-------->| IANA root |
   +-----------+   signs  +--------------+  signs  +-----------+

In the IANA root, ICANN is the holder of the KSK, and Verisign is the
holder of the ZSK. There is a key signing ceremony where Verisign
submits the ZSK to ICANN and they are signed.

In the original Yeti setup, the setup was very similar:

   +-----------+          +--------------+         +-----------+
   | Yeti KSK  |--------->| Yeti ZSK     |-------->| Yeti root |
   +-----------+   signs  +--------------+  signs  +-----------+

However, in the Yeti setup both the KSK and ZSK were each held by all
three DM. This meant that each DM operator had full access to all of
the secret material in the Yeti setup.

The MZSK experiment changes this setup, so that each DM operator
creates a separate ZSK, which is used to sign the Yeti root, looking
something like this:

                          +--------------+         +-----------+
                 +------->| BII ZSK      |-------->| Yeti root |
                 | signs  +--------------+  signs  +-----------+
   +-----------+ |        +--------------+         +-----------+
   | Yeti KSK  |-+------->| TISF ZSK     |-------->| Yeti root |
   +-----------+ | signs  +--------------+  signs  +-----------+
                 |        +--------------+         +-----------+
                 +------->| WIDE ZSK     |-------->| Yeti root |
                   signs  +--------------+  signs  +-----------+


In the MZSK setup, each DM maintains a separate ZSK and produces a
version of the root zone with different signatures. Aside from the
signatures, the contents of the Yeti root zone is identical.

In DNSSEC, the KSK and ZSK are all returned in a single value, the
DNSKEY Resource Record Set (RRset). Because of this, DNSSEC resolvers
are able to validate answers as long as they are signed by any of the
ZSK.

This experiment was necessary to:

1. Confirm that DNSSEC resolvers continue to function properly with
   a MZSK setup.
2. Confirm that the Yeti system would continue to function properly
   with an MZSK setup.
3. Investigate the impact on the network with an MZSK setup.

The third item was important because the size of the DNSKEY RRset is
bigger, and this means that the answers are more likely to get
fragmented or dropped by networks.

The MZSK experiment proposal and more details are documented in
Experiment-MZSK[2].

Experiment Protocol
===================
The Yeti project uses an experiment protocol, documented in
Experiment-Protocol[3]. The MZSK experiment followed this protocol,
which has four parts:

1. Proposal
2. Lab Test
3. Yeti Test
4. Report of Findings

The first three have concluded and this document is the final part.

Lab Test
========
In preparation for the experiment, BII engineers led by Davey Song
conducted a lab test to verify the behavior of DNS resolvers under
controlled conditions.

In the lab test, a DNS resolver was configured using two experimental
root servers. Traffic was sent insuring that the resolver had the ZSK
from one or both of the servers, and then the validation results
checked.

The lab test confirmed that if a root server tried to use a ZSK that
was not present in the DNSKEY RRset that it would fail, but that even
if two servers used separate ZSK this resolves properly as long as
they are both present in the DNSKEY RRset.

The full details of this lab test can be found in the attachment to
the proposal mail[4] sent to the Yeti discussion mailing list.

Project Timeline
================

## 2015-10-20

Davey Song sent a mail[4] to the Yeti discussion mailing list proposing
that Yeti conduct the MZSK experiment. This included the results of
the previously-run lab test.

## 2016-01-22

Davey Song sent a more detailed proposal[5] explaining the way the
experiment would work to the Yeti discussion mailing list.

## 2016-02-17

Additional ZSK were added to the Yeti root DNSKEY RRset, at a rate of
one ZSK per serial number, until there were 6 total. This completed on
2016-02-19.

## 2016-03-14

Phase 2 of the experiment started, with non-shared ZSK added to the
Yeti root as follows:

* BII on 2016-03-14
* TISF on 2016-03-17
* WIDE on 2016-03-22

In each case the key was activated 2 days later, which means that it
was then used by the DM to sign the root zone.

## 2016-04-25

The experiment was concluded[6].

Observations & Results
======================

## 2016-02-18

We observed that the packet size has already increased to more than
1280 bytes, which means that most DNS servers will fragment the
responses. We observe this in practice:

    09:50:07.183524 IP6 2001:470:78c8:2:224:9bff:fe13:3a9c.44664 > 240c:f:1:22::6.53: 19840+ [1au] DNSKEY? . (28)
    09:50:07.485850 IP6 240c:f:1:22::6 > 2001:470:78c8:2:224:9bff:fe13:3a9c: frag (0|1232) 53 > 44664: 19840*- 8/0/1 DNSKEY, DNSKEY, DNSKEY, DNSKEY, DNSKEY, DNSKEY, RRSIG, RRSIG[|domain]
    09:50:07.485850 IP6 240c:f:1:22::6 > 2001:470:78c8:2:224:9bff:fe13:3a9c: frag (1232|258)

`tcpdump` with a "port 53" filter do not see these fragments.

We noticed that one of the DM (TISF) is using two RRSIG for the DNSKEY
RRset. This was judged to be an implementation error by TISF and
quickly corrected.

The RIPE Atlas measurements, one of our data sets, did not have the DO
bit set when created. A new set was created, and the old ones are
still available.

## 2016-02-19

After add we added the sixth ZSK, we found that query DNSKEY on
`yeti.aquaray.com` via UDP failed:

    $ dig . @yeti.aquaray.com -t dnskey +dnssec 

TCP for the server worked:

    $ dig . @yeti.aquaray.com -t dnskey +dnssec +tcp

Smaller UDP queries worked too:

    $ dig . @yeti.aquaray.com -t ns +dnssec +tcp

This was reported on the Yeti list, and fixed shortly after:

http://lists.yeti-dns.org/pipermail/discuss/2016-February/000393.html

The underlying cause was a bug in Linux where IPv6 fragmented packets
were not forwarded on an Ethernet bridge with netfilter `ip6_tables`
loaded. The issue documented here:

https://github.com/torvalds/linux/commit/efb6de9b4ba0092b2c55f6a52d16294a8a698edd

## 2016-02-22

A problem was discovered where having multiple ZSK causes problems
with IXFR.

IXFR is incremental zone transfer, and is a series of delete and add
operations. However, since each DM has a separate set of signatures it
has different RRSIG records. This means that the delete sequence from
one DM is different from another DM, which means that the Yeti root
servers that try to get the root zone from multiple DM will fail if
this happens and they are trying to use IXFR.

The NSD DNS server will detect this condition and consider it an
error, retrying with a full zone transfer (AXFR).

The Knot server appears to simply ignore delete that it does not
recognize, which results in a zone with both the old and new
signatures. This will properly validate, although the old signatures
will expire and become "junk" data.

The current solutions are to use full zone transfers (AXFR) or for a
given Yeti root server to only ever use a single DM.

The problem was discovered and introduced on the Yeti discuss list
here:

http://lists.yeti-dns.org/pipermail/discuss/2016-February/000399.html


Analysis of Captured Packets
============================


Conclusions
===========

Using separate signers who have independent ZSK works for the root
zone. Validating resolvers can continue to validate the contents of
the root zone. The DNS zone transfer system works, although some
caution is needed.

Since the MZSK model works and provides some operational benefit, the
Yeti project has left it in place and it is now the standard way that
Yeti root zones are signed.


[1] https://github.com/BII-Lab/Yeti-Project/blob/master/doc/Yeti-DM-Setup.md
[2] https://github.com/BII-Lab/Yeti-Project/blob/master/doc/Experiment-MZSK.md
[3] https://github.com/BII-Lab/Yeti-Project/blob/master/doc/Experiment-Protocol.md
[4] http://lists.yeti-dns.org/pipermail/discuss/2015-October/000269.html
[5] http://lists.yeti-dns.org/pipermail/discuss/2016-January/000362.html
[6] http://lists.yeti-dns.org/pipermail/discuss/2016-April/000501.html
