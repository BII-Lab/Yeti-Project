# Yeti Algorithm Rollover Experiment

Before ICANN rolled its KSK successfully on 15th October 2018, we had rolled Yeti KSK in Yeti testbed twice in 2017. It has been proved that rolling with a different key is not easy for DNS Root system due to varying behavior of the DNS installed base. However, it is considered more challenging to roll the DNSSEC algorithm on the root (roll the key with different algorithm).

Like rolling with a different key, rolling with a different algorithm has security benefit. Moreover, rolling from current RSA/SHA256 to ECDSA p-256 has benefit to generate smaller size of the RRSIG, DNSKEY and DS records.

# Methodology

Different from the conservative approach proposed in [section 4.1.4.2 of RFC6781](https://tools.ietf.org/html/rfc6781#section-4.1.4.2), Yeti Algorithm Rollover is similar with the prior [Yeti KSK rollover](https://github.com/BII-Lab/Yeti-Project/blob/master/doc/Experiment-KROLL2.md), **adopting a liberal approach and only rolling KSK with Double-DS rollover**. It is explained why we choose this approach as follows:

* The reasons of only rolling KSK is that some people suggested that some resolver may not tolerate a KSK and a ZSK using different algorithms in the same zone (notably PowerDNS). We need to investigate this with more details.

* The reasons of choosing liberal approach are twofold: 1) [Algorithm rollover in .SE](https://www.sidnlabs.nl/downloads/presentations/Rolling%20with%20Confidence%20Managing%20the%20Complexity%20of%20DNSSEC%20Operations.pdf) shows that conservative algorithm rollover is not necessary (only 6 out of 10000 failed). 2)Yeti algorithm rollover is deliberately design to expose more possible failures.

* The reason of choosing Double-DS KSK rollover method lies in that 1) it is our prior Yeti KSK rollover approach and, 2) our deliberate violation of saying in section 4.1.4 of RFC6781. We think it does not apply in Algorithm rollover for root because Root has no parents.

>"Note that the Double-DS KSK rollover method cannot be used, since
   that would introduce a parental DS of which the apex DNSKEY RRset has
   not been signed with the introduced algorithm."--section 4.1.4 of RFC6781


# Description of the Yeti Algorithm rollover

Different with the KSK roll, The new KSK uses the ECDSA p-256 algorithm with a 256 bits key which is shorter than RSA/SHA-256 algorithm with a 2048 bit key. It is generated on software, and stored on systems secured with similar security to enterprise computing resources; no HSM is used.

## Time schedule 

It will follow the timings described in RFC 5011, to allow resolvers to automatically update their trust anchors.

https://tools.ietf.org/html/rfc5011

The time schedule of Yeti Algorithm rollover looks exactly like prior Yeti KSK rollover which looks like this as follows (Our "slots" will be 10 days long): 

|           |  slot 1  |  slot 2  |  slot 3  |  slot 4  |  slot 5  |  slot 6  |  slot 7  |  slot 8  |  slot 9  |
|-----------|----------|----------|----------|----------|----------|----------|----------|----------|----------|
| **59302** | pub+sign | pub+sign | pub+sign | pub+sign | pub+sign |   pub    |   pub    | revoke   |          |
|  **new**  |          |   pub    |   pub    |   pub    |   pub    | pub+sign | pub+sign | pub+sign | pub+sign |

## Experiment plan 

As with the prior KSK rollover, We will do the following:

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

1. Generate a new KSK using ECDSA p-265 algorithm. This will be placed into the DM synchronization repository. The DM synchronization is described here:

   https://github.com/BII-Lab/Yeti-Project/blob/master/doc/Yeti-DM-Sync.md

   This KSK will appear in the Yeti root, but not be used for signing.

2. Wait 40 days.

3. Use the new KSK to sign the DNSSEC RRset.

4. Wait 20 days.

5. Set the "revoked" flag on the old KSK and place that into the DM
   synchronization repository. The DNSKEY RRset will be signed with the old and
   the new KSK.

6. Wait 10 days.

7. Remove the old KSK at each distribution master.


## Rollback Procedures

It is unlikely that an error occurs while still using the old KSK for
signing. If this happens, then we can simply remove the new KSK.

If an problem happens after changing to the new KSK, we can go back to
the old KSK before we add the KSK with the "revoked" flag set. If this
happens, we will remove the new KSK.

If a problem happens after we publish the old KSK with the "revoked"
flag set, we will not be able to simply go back to the old KSK, since
it will have the "revoked" flag set. Depending on the nature of the
failure, resolver operators may need to update their configurations
manually to fix the problem. This will be announced on the Yeti
Discuss list as well as on the Yeti website.

## What to Measure: Fragmentation & Packet Loss

Since fragmentation and packet loss are questions that Yeti was
started to investigate, we will look carefully at these.

We will set up RIPE Atlas measurements which should be able to spot
UDP responses that do not reach the resolver. We can do this by
using the local resolver and looking for dropped packets.

We will write a script which will detect fragmentation at the resolver
side. We will run this on our resolvers and ask Yeti participants to
also run this script.


## What to Measure: Validation Failure

We set up checks for the experiment to confirm that we can lookup
and validate a range of signed zones, using both BIND 9 and Unbound. We will
keep these in place for the Algorithm rollover experiment.