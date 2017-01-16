# Yeti Project Report: KSK Roll Experiment (KROLL)
**Version: 1.0**  
**Date: 2017-01-09**  

# Introduction
Yeti DNS System is a live testbed for Root DNS Server System:

    https://yeti-dns.org/

In late 2016, the Yeti project ran the KSK Roll (KROLL) Experiment,
designed to perform a single KSK roll for the Yeti root and observe
the effects.

The Yeti root KSK rollover was originally planned to use the KSK
Double-DS Rollover as described in RFC 6787, although without
publishing the DS in the parent (since the root has no parent):

https://tools.ietf.org/html/rfc6781#section-4.1.2

However, the timings worked out did not include a double-signing
period. This period was designed to allow synchronization with the
parent DS, which does not exist in the case of the root.

It followed the timings described in RFC 5011, to allow resolvers to
automatically update their trust anchors:

https://tools.ietf.org/html/rfc5011

This experiment covers a simple KSK roll. Note that this was _NOT_ the
same as the proposed KSK rollover that ICANN is going to use for the
IANA root. You can find more details about that process here:

https://www.icann.org/resources/pages/ksk-rollover

An experiment to duplicate conditions similar to the ICANN roll will
be performed later.

The KSK experiment proposal and more details are documented in
Experiment-KROLL<sup>[1]</sup>.


# Description of the Yeti root KSK 
The Yeti root KSK uses the RSA/SHA-256 algorithm with a 2048 bit key,
the same as the IANA root KSK. It is generated on software, and stored
on systems secured with similar security to enterprise computing
resources; no HSM is used, and no published procedures exist for
accessing or updating the KSK.


# Prior Experience with KSK Roll

Early in the Yeti project the Yeti KSK was rolled in an unplanned
fashion. This was done because the default KSK timings from the
utility that generated the keys, dnssec-keygen, were set up to do a
KSK roll. This resulted in errors because it did not follow the RFC
5011 hold-down timer recommendations. BIND 9 continued to function,
because it does not follow the RFC 5011 recommendations, but Unbound
failed, because it does.

These results are documented in the Yeti Testbed Experience Internet
Draft<sup>[2]</sup>.


# Experiment Protocol
The Yeti project uses an experiment protocol, documented in
Experiment-Protocol<sup>[3]</sup>. The KROLL experiment did not follow
this protocol. Normally there are:

1. Proposal
2. Lab Test
3. Yeti Test
4. Report of Findings

In the case of the KROLL we already had experience because of the
unplanned KSK roll early on in the Yeti project, so we decided to omit
the lab test. So for the KROLL experiment we simply followed:

1. Proposal
2. Yeti Test
3. Report of Findings

This document is the report of findings.

# Experiment Plan

The basic plan was "do it and see what happens".

1. Generate a new KSK. This was to be placed into the Distribution
   Master (DM) synchronization repository. The DM synchronization is
   described here:

   https://github.com/BII-Lab/Yeti-Project/blob/master/doc/Yeti-DM-Sync.md

   This KSK would then appear in the Yeti root, but not be used for
   signing.

2. Wait 30 days.

3. Set the "revoked" flag on the old KSK and place that into the DM
   synchronization repository. The ZSK would then be signed with the
   old and the new KSK.

4. Wait 30 days.

5. Remove the old KSK at each distribution master.


# Experiment Timeline

## 2016-07-04

Shane Kerr sent a proposal to the Yeti discussion list proposing that
Yeti conduct the KROLL experiment:

http://lists.yeti-dns.org/pipermail/discuss/2016-July/000625.html

## 2016-07-08

A new KSK was added, starting the KROLL experiment.

## 2016-07-11

An error was made in creating the KSK. An incorrect flag meant this
was actually created as a ZSK, so the experiment was re-started using
an actual KSK.

## 2016-07-23

Kees Monshouwer noticed that the documentation for setting up a new
Yeti resolver was still using the old KSK. This meant that any
resolver configured during this time would fail when the new KSK
rolled.

http://lists.yeti-dns.org/pipermail/discuss/2016-July/000657.html

Because of this we reset the timers for the KSK to allow another 30
days, after including the new KSK in the published configuration. We
announced this change 2016-08-02 (see below).

## 2016-07-25

Kees Monshouwer pointed out that the signature duration used in Yeti
would allow a replay attack resulting in a denial of service against a
resolver, because of the hold-down timer.

http://lists.yeti-dns.org/pipermail/discuss/2016-July/000664.html

While initially overlooked, an IETF draft on this issue raised
awareness:

http://lists.yeti-dns.org/pipermail/discuss/2016-September/000694.html

We decided to continue the experiment with the potential denial of
service attack in place, since the attack is quite difficult to do in
practice, and the Yeti resolvers are both experimental and relatively
closely watched, and the impact of a such an attack would be quite low
(updating the trust anchor for the resolver would fix it).

## 2016-08-02

We announced the restarting of the KSK rollover timings based on the
missing KSK.

Additionally, we announced that we would not be double-signing as
originally planned, but would skip that phase. The consensus was that
since the reason for double-signing is alignment with the DS record in
a parent that this is not necessary, since the root zone has no parent
and thus no DS records in the parent zone.

http://lists.yeti-dns.org/pipermail/discuss/2016-August/000675.html

## 2016-08-31

The KSK roll was completed, and the revoked bit set on the old KSK.
One of the three DM failed to publish the KSK with the revoke bit
set, delaying the revocation of the old KSK by resolvers who saw the
DNSKEY RRset published by that DM.

# Observations & Results

While rolling the Yeti KSK was successful, there were a number of
issues that arose during the experiment which may be important for the
IANA KSK roll, as well as future Yeti KSK rolls.

## Communication of KSK Roll

We overlooked the documentation where new Yeti resolvers were
configured, and needed to restart the KSK roll to allow the RFC 5011
timer of new resolvers to work properly. ICANN will have to try to
track down all locations where the IANA trust anchor is published and
insure that none of them are outdated. Unfortunately not all of these
documents are written or maintained by ICANN, so this will be a
difficult task.

## Potential Denial of Service

As Kees Monshouwer noted, there is a potential replay attack that can
cause a denial of service for resolvers. This happens when an attacker
sends an old DNSKEY RRset answer that has RRSIG signatures with
still-valid lifetimes. The resolver will accept them, and this will
reset the RFC 5011 hold-down timer. If the new value is past the KSK
roll period, then it will cause the resolver to fail.

This has been written up as an IETF draft by Wes Hardaker and Warren
Kumari:

https://tools.ietf.org/html/draft-hardaker-rfc5011-security-considerations-01

It does not appear to affect the IANA KSK roll, because the signature
lifetimes are shorter than for Yeti and because the roll extends over
a much longer period.

We should adjust the signature lifetime for Yeti for future rolls, as
well as trying to create the DoS in the Yeti platform to confirm the
possibility.

## BIND Trust Anchor Configuration and Views

During the KSK rollover, it was discovered that a view added to a BIND
9 resolver did not use the same RFC 5011 timings as other views,
including the default view. An administrator who expects that a BIND 9
resolver will handle RFC 5011 KSK rollover for all zones identically
will have views that fail to resolve when the KSK roll happens.

This is a serious issue. Administrators often run older versions of
BIND, so even if the default behavior or the software is changed, this
new version would not be widely installed. Any BIND 9 operator running
a resolver who adds a view during the month before the IANA KSK
rollover completes will end up with an invalid trust anchor and that
view would fail DNS resolution.

We have approached the BIND 9 developers and also mentioned this in
the DNS OARC meeting. We will be following up on this issue as the IAN
KSK roll approaches.

# Analysis of Captured Packets

_This section will be revised after analysis of the captured packets,
which have been stored in an Entrada database._

# Conclusions

The basic mechanisms in the DNSSEC protocol for rolling a KSK at the
root work. Some care must be taken to insure proper communications and
timings. A worrying issue remains in BIND 9's handling of trust
anchors for views.

-----

1: https://github.com/BII-Lab/Yeti-Project/blob/master/doc/Experiment-KROLL.md
[1]: https://github.com/BII-Lab/Yeti-Project/blob/master/doc/Experiment-KROLL.md
2: https://github.com/BII-Lab/Yeti-Project/blob/master/doc/Experiment-Protocol.md
[2]: https://github.com/BII-Lab/Yeti-Project/blob/master/doc/Experiment-Protocol.md
3: https://tools.ietf.org/html/draft-song-yeti-testbed-experience-03#section-4.5
[3]: https://tools.ietf.org/html/draft-song-yeti-testbed-experience-03#section-4.5
