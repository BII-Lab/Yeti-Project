Introduction
------------
This document lays out the current proposed timeline of upcoming
experiments. It contains a brief summary of each as well as links to
further information.

Process
-------
The planning of experiments is organized by consensus on the Yeti
discuss mailing list. The Yeti coordinators will make the final
decision on what experiments will run.

The list of experiments is meant to be updated regularly, as
experiments complete and new ideas are proposed.

Timeline
--------

| Start Date | End Date   | ID    | Experiment
|------------|------------|-------|--------
| 2016-02-01 | 2016-02-19 | MZSK  | Multi-ZSK
| 2016-02-22 | 2016-04-08 | KROLL | KSK Roll
|            |            | RENUM | Root Server Renumbering
|            |            | IROLL | ICANN KSK Roll Simulation
|            |            | 5011X | RFC 5011 Roll-Back
|            |            | FAKER | Lots of Root Servers
|            |            | DOT-Y | Rename Servers to .YETI
|            |            | PMTNC | Priming Truncation
|            |            | BGZSK | ZSK 2048 Bits
|            |            | ECDSA | KSK ECDSA Roll
|            |            | FSTRL | Frequent ZSK Roll
|            |            | TCPRT | TCP-only Root
                          

Experiments
-----------

### MZSK: Multi-ZSK

The Multi-ZSK experiment is designed to test operating the Yeti root
using more than a single ZSK. The goal is to have each distribution
master (DM) have a separate ZSK, signed by a single KSK. This will
allow DM to operate independently, each maintaining their own key
secret material.

The preliminary, lab-research has been completed. This experiment does
not require any specific changes on the part of the Yeti root
operators or the Yeti resolver operators.

http://lists.yeti-dns.org/pipermail/discuss/2015-October/000269.html

Details need to be finished before the experiment starts, such as the
exact measurements, a detailed timeline, and the format of the final
report.

### KROLL: KSK Roll

The KSK Roll experiment is designed to verify that a KSK roll of the
Yeti root works properly. Unlike the IANA root we do not expect a
large number of unmanaged resolvers, and if any resolver fails then
this is useful information rather than a serious service outage.

The process will probably look something like the proposed Yeti Root
KSK rollover procedure:

https://github.com/shane-kerr/Yeti-Project/blob/ksk-roll-plan/doc/KSK-rollover.md

It will also exercise the KSK rollover communication plan:

https://github.com/shane-kerr/Yeti-Project/blob/yeti-ksk-communication-plan/doc/KSK-rollover-communication-plan.md

Details need to be finished before the experiment starts, such as the
exact measurements, a detailed timeline, and the format of the final
report.

We may wish to include some resolver-side signaling about trust
anchor configuration such as that defined in:

https://tools.ietf.org/html/draft-wkumari-dnsop-trust-management-01

### KROLL: ICANN KSK Roll Simulation

ICANN has a team of experts working to define the process for rolling
the IANA root zone KSK. The proposal is not yet final, but when it is
the Yeti project should try to run a simulation of the process. There
will be many differences, but it seems important to try to duplicate
the IANA process as closely as is practical and observe the results.

This experiment depends on the ICANN KSK roll team publishing a final
recommendation. Once that happens, designing and running an experiment
seems a reasonable priority.

### RENUM: Root Server Renumbering

One of the goals of the Yeti project is to investigate the impact of
renumbering root name servers. We should devise an experiment to
measure various renumbering schemes and the impact. For example, we
could ask a set of root operators to listen on multiple addresses,
which would allow the coordinators to update the published set of root
server addresses.

This experiment could also be used to test the impact of resolvers
that use automated ways to update their root hint file as well as
those who do not.

### 5011X: RFC 5011 Roll-Back

RFC 5011 has a 30-day hold-down timer for newly introduced trust
anchors. We should test what happens if this is actually needed, by
simulating a bogus added KSK.

### FAKER: Lots of Root Servers

The current set of root server operators only results in a message of
881 bytes from a priming query. This results in packets smaller than
the 1280 byte IPv6 minimum MTU size, and also smaller than the normal
1500 byte Ethernet frame size which would be exceeded by 1460 byte
IPv6 DNS messages. Exceeding these limits would provide useful
information about scaling the root.

The basic idea is to increase the size of the reply to the priming
query by adding "fake" root servers. We can use using multiple IP
addresses on all or several of the Yeti root servers. Using different
names would also expand the packets, and having those names from
different domains would defeat DNS label compression and expand the
packets further.

Example just adding addresses:

    bii.dns-lab.net. AAAA 240c:f:1:22::6
                     AAAA 240c:f:1:22::66
                     AAAA 240c:f:1:22::666
                     AAAA 240c:f:1:22::6666

Example using different names:

    bii.dns-lab.net. AAAA 240c:f:1:22::6
    cjj.dns-lab.net. AAAA 240c:f:1:22::66
    dkk.dns-lab.net. AAAA 240c:f:1:22::666
    ell.dns-lab.net. AAAA 240c:f:1:22::6666

Example with name from different domains:

    bii.dns-lab.net. AAAA 240c:f:1:22::6
    bii.dns-fab.cn.  AAAA 240c:f:1:22::66
    bii.dns-cab.net. AAAA 240c:f:1:22::666
    bii.dns-dab.cn.  AAAA 240c:f:1:22::6666

The experiment would likely consist of adding enough fake root servers
to bring the packet to just under a size limit, then just over. This
would probably be useful at:

* 1280 bytes, the message size in IPv6 at the minimum MTU
* 1420 bytes, the amount of space left for a DNS message in an IPv6
  packet via an IPv6 tunnel on a 1500 byte Ethernet frame 
* 1440 bytes, the amount of space left for a DNS message in an IPv6
  packet via an IPv4 tunnel on a 1500 byte Ethernet frame 
* 1460 bytes, the amount of space left for a DNS message in a normal
  IPv6 packet in a 1500 byte Ethernet frame

A couple days around each boundary should be enough to get good packet
traces for analysis.

### DOT-Y: Rename Servers to .YETI

In support of the ICANN RSSAC Caucus work on naming of root servers,
Yeti can conduct an experiment where the Yeti root servers are put
into the Yeti root zone directly, rather than each with a separate
name from a separate space. This may be considered a modification of
the root zone, so may be out of scope. Discussion is needed.

### PMTNC: Priming Truncation

We can measure the worst-possible case for priming truncation by
truncating all priming query answers. This requires either custom
software on all participating Yeti root servers, either modified
server software or perhaps a proxy.

This experiment can provide input into the expected outcome of work
that expands the priming answers, such as increasing the ZSK key
length.

### BGZSK: ZSK 2048 Bits

RSA 1024 is no longer recommended for cryptography. At some point the
ZSK should be made longer. Common practice is to adopt 2048 bits keys.

Yeti should change to RSA 2048 for ZSK and observe the results. If the
response size is greater than 1280 bytes it is likely that increased
TCP will be observed from priming queries.

### ECDSA: KSK ECDSA Roll

One possible way to reduce packet sizes is to change to an ecliptic
curve for signing. ECDSA is a standard way of doing that in DNSSEC.
While in principle this can be done separately for the KSK and the
ZSK, the RIPE NCC has done research recently and discovered that some
resolvers require that both KSK and ZSK use the same algorithm. Even
if this is fixed in latest versions of the code, old versions will be
in place for some time.

https://labs.ripe.net/Members/anandb/dnssec-algorithm-roll-over

This means that an algorithm roll also involves a KSK roll.
Performing an algorithm roll at the root is an interesting challenge.

### FSTRL: Frequent ZSK Roll

We want to see the limits of how frequently a root ZSK can roll. This
will be relatively safe after the Multi-ZSK setup is finished. This
has a lower bound based on TTL, but the TTL can be modified for such
an experiment. A ZSK roll might be something that can be done daily or
even at a faster rate.

### TCPRT: TCP-only Root

Similar to truncating priming queries, we can actually use the same
technique to truncate _all_ answers from root servers. This should
give some insight into the usefulness of TCP-only DNS in general.

Completed Experiments
---------------------
Completed experiments will be listed here, along with a link to a
paper or other document describing the results.

No experiments have been completed yet.
