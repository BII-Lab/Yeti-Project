Yeti KSK 2nd Rollover Experiment (KROLL2)
=========================================
Yeti has successfully performed a KSK roll, in the KROLL experiment.
We would like to perform another KSK roll before the ICANN KSK roll
begins, adding more information to the earlier roll.

Like the 1st Yeti root KSK rollover, the 2nd Yeti root KSK rollover
will use the KSK Double-DS rollover as described in RFC 6787, although
without publishing the DS in the parent (since the root has no parent):

https://tools.ietf.org/html/rfc6781#section-4.1.2

It will follow the timings described in RFC 5011, to allow resolvers
to automatically update their trust anchors.

https://tools.ietf.org/html/rfc5011

We will use similar phases to the IANA roll, although with different
timings so that we can finish the roll faster and because we do not
have the same strict timing constraints that ICANN does. Our "slots"
will be 10 days long, and look like this:

|           |  slot 1  |  slot 2  |  slot 3  |  slot 4  |  slot 5  |  slot 6  |  slot 7  |  slot 8  |  slot 9  |
|-----------|----------|----------|----------|----------|----------|----------|----------|----------|----------|
| **19444** | pub+sign | pub+sign | pub+sign | pub+sign | pub+sign |   pub    |   pub    | revoke   |          |
|  **new**  |          |   pub    |   pub    |   pub    |   pub    | pub+sign | pub+sign | pub+sign | pub+sign |



Description of the Yeti root KSK 
================================
As with the first KSK roll, te Yeti root KSK uses the RSA/SHA-256
algorithm with a 2048 bit key, the same as the IANA root KSK. It is
generated on software, and stored on systems secured with similar
security to enterprise computing resources; no HSM is used, and no
documented procedures exist for access or updating the KSK.


Experiment Plan
===============

We would like to verify the 

We will do the following:

0. Update the RRSIG duration.   
   We need to update the RRSIG validity period to avoid the replay DoS
   attack described in
   [draft-hardaker-rfc5011-security-considerations]([https://datatracker.ietf.org/doc/draft-hardaker-rfc5011-security-considerations/).
   The IANA root is safe from this, but currently Yeti is vulnerable.
   Since we will use 10-day slots, we need to insure that the RRSIG is
   not valid too long. The Yeti root has a 1 day TTL on DS and RRSIG
   records, so if we make the RRSIG validity period 1 week (7 days)
   then adding 1 slot (10 days) to the 30-day RFC 5011 hold-down timer
   should ensure that no replay attack is possible.

1. Generate a new KSK. This will be placed into the DM synchronization
   repository. The DM synchronization is described here:

   https://github.com/BII-Lab/Yeti-Project/blob/master/doc/Yeti-DM-Sync.md

   This KSK will appear in the Yeti root, but not be used for signing.

2. Wait 40 days.

3. Use the new KSK to sign the zone. The old ZSK will be signed with
   the old and the new ZSK.

4. Wait 20 days.

5. Set the "revoked" flag on the old KSK and place that into the DM
   synchronization repository. The ZSK will be signed with the old and
   the new KSK.

6. Wait 10 days.

7. Remove the old KSK at each distribution master.


Rollback Procedures
===================
It is unlikely that an error occurs while still using the old KSK for
signing. If this happens, then we can simply remove the new KSK.

If an problem happens after changing to the new KSK, we can go back to
the old KSK until we add the KSK with the "revoked" flag set. If this
happens, we will remove the new ZSK.

If a problem happens after we publish the old KSK with the "revoked"
flag set, we will not be able to simply go back to the old KSK, since
it will have the "revoked" flag set. Depending on the nature of the
failure, resolver operators may need to update their configurations
manually to fix the problem. This will be announced on the Yeti
Discuss list as well as on the Yeti website.


What to Measure: EDNS Key Tag
=============================
We will test the effectiveness of the key tag methods described in 
[draft-ietf-dnsop-edns-key-tag](https://datatracker.ietf.org/doc/draft-ietf-dnsop-edns-key-tag/).

As far as we know, no resolvers have implemented the EDNS methodology
described in the draft. (BIND 9, Unbound, Knot Resolver, and PowerDNS
Recursor seem to make no mention of the draft.) However, we can
implement the Key Tag Query method via an external program and install
this at participating resolvers.

These resolvers will send a query in a specific format (`QTYPE=NULL`,
`QCLASS=IN`, `QNAME=_ta-4bf4.`). We can then verify that these queries
appear at the Yeti root servers.


What to Measure: Fragmentation & Packet Loss
============================================
Since fragmentation and packet loss are questions that Yeti was
started to investigate, we will look carefully at these.

We will set up RIPE Atlas measurements which should be able to spot
UDP responses that do not reach the resolver. We can do this by
using the local resolver and looking for dropped packets.

We will write a script which will detect fragmentation at the resolver
side. We will run this on our resolvers and ask Yeti participants to
also run this script.


What to Measure: Validation Failure
===================================
We set up checks for the MZSK experiment to confirm that we can lookup
and validate a range of zones, using both BIND 9 and Unbound. We will
keep these in place for the KROLL2 experiment.



Timeline
========
The experiment will start on 2017-02-20.

```
Slot 1: 2017-02-20 to 2017-03-01   change the RRSIG validity period
Slot 2: 2017-03-02 to 2017-03-11   publish the new KSK
Slot 3: 2017-03-12 to 2017-03-23   publish the new KSK
Slot 4: 2017-03-24 to 2017-04-03   publish the new KSK
Slot 5: 2017-04-03 to 2017-04-13   publish the new KSK
Slot 6: 2017-04-14 to 2017-04-23   sign with the new KSK
Slot 7: 2017-04-24 to 2017-05-03   sign with the new KSK
Slot 8: 2017-05-04 to 2017-05-13   revoke the old KSK
Slot 9: 2017-05-14 to 2017-05-23   no longer publish the old KSK
```


Report Format
=============
As with prior experiments, when the KROLL2 experiment is complete we
will produce a final report.

This will include the motivation and actions taken, as well as any
observations made during the experiment. The results of traffic
analysis will be included, along with a conclusion.
