# Yeti Algorithm Rollover Experiment in lab environment 

Before ICANN rolled its KSK successfully on 15th October 2018, we had rolled Yeti KSK in Yeti testbed twice in 2017. It has been proved that rolling with a different key is not easy for DNS Root system due to varying behavior of the DNS installed base. However, it is considered more challenging to roll the DNSSEC algorithm on the root (roll the key with different algorithm).

Like rolling with a different key, rolling with a different algorithm has security benefit. Moreover, rolling from current RSA/SHA256 to ECDSA p-256 has benefit to generate smaller size of the RRSIG, DNSKEY and DS records.

However, there are some uncertainties on KSK algorithm rollover which will result no reliable approach. RFC6781 gives a specification for [Algorithm Rollover, RFC 5011 Style](https://tools.ietf.org/html/rfc6781#section-4.1.4.2) which follows a conservative approach. But some practice suggest the liberal approach is also acceptable for Algorithm rollover. In addition, it is not sure whether it is OK to roll the algorithms of the KSK signatures and ZSK signatures separately. So it is wise to test all the possible approaches in lab environment to verify each of them (observations of failure are also valuable) and confirm the reliable one before we proceed in the Yeti testbed for large-scale experiment.  

There are 4 possible approaches worth of testing:

**Case 1: Roll only KSK algorithm with Double-DS approach (Figure 5 of RFC6781). (PS:It is going to fail due to the violation of RFC6781.)** 
   * Pre-publish the new KSKs (one is stand-by ksk) in the root zone to fit RFC5011. 
   * Wait a period of RFC5011 Add Hold-Down Time, 40 days. 
   * Change the RRSIG of DNSKEY in a flag day. Wait 10 days
   * Revoke the old KSK and sign DNSKEY RRset with both old and new key
   * Remove the old KSK and RRSIG of DNSEKY,2 days later

**Case 2: Roll only KSK algorithm with liberal and double signature approach (Figure 4 of RFC6781)**
   * Add both the new KSKs (one is stand-by ksk) and RRSIG of DNSKEY in the zone to fit RFC6781.
   * Wait a period of RFC5011 Add Hold-Down Time, 40 days.
   * Revoke the old key and keep double signature in the zone. Wait 10 days
   * Remove the old KSK and RRSIG of DNSEKY

**Case 3: Roll the algorithm both KSK and ZSK with liberal and double-signature approach**
   * Add new ZSK and KSKs (one is stand-by ksk) as well as RRSIG signed by these keys in the zone, and wait for 10 days.Wait a period of RFC5011 Add Hold-Down Time，40 days.
   * Revoke the old KSK and keep double signature in the zone, wait for 10 days
   * Remove the old KSK and ZSK as well as the RRSIG signed by old KSK and ZSK.

**Case 4：Roll the algorithm both KSK and ZSK with conservative and double-signature approach( recommended in Figure 13 of RFC6781)**
   * Add the RRSIG signed by new ZSK, and wait for 10 days
   * Add new ZSK and KSKs (one is stand-by ksk) as well as RRSIG signed by one KSK. Wait a period of RFC5011 Add Hold-Down Time，40 days.
   * Revoke the old KSK and keep double signature in the zone, and wait for 10 days
   * Remove the old KSK and ZSK as well as the RRSIG signed by old KSK keeping RRSIG signed by old ZSK in the zone, and wait 10 days later
   * Remove the RRSIG signed by old ZSK

Different with the KSK roll, The new KSK uses the ECDSA p-256 algorithm with a 256 bits key which is shorter than RSA/SHA-256 algorithm with a 2048 bit key. It is generated on software, and stored on systems secured with similar security to enterprise computing resources; no HSM is used.

Note that we deliberately shorten the remove hold-down time which is irrelevant for the experiment.

## Time schedule

Note The "slots" will be 10 days long for each timing table. 

Time schedule for case 1: 

|           |  slot 1  |  slot 2  |  slot 3  |  slot 4  |  slot 5  |  slot 6  |  slot 7  |  slot 8  |  slot 9  |
|-----------|----------|----------|----------|----------|----------|----------|----------|----------|----------|
| **old KSK** | pub+sign | pub+sign | pub+sign | pub+sign | pub+sign | pub   |   revoke+sign   | |       |
|  **new KSK**  |          |   pub    |   pub    |   pub    |   pub    | pub+sign | pub+sign | pub+sign | pub+sign |
|  **stand-by KSK**  |          |   pub    |   pub    |   pub    |   pub    | pub | pub | pub | pub |


Time schedule for case 2:

|           |  slot 1  |  slot 2  |  slot 3  |  slot 4  |  slot 5  |  slot 6  |  slot 7  |  slot 8  |  slot 9  |
|-----------|----------|----------|----------|----------|----------|----------|----------|----------|----------|
| **old KSK** | pub+sign | pub+sign | pub+sign | pub+sign | pub+sign | pub | Revoke+sign |     |          |
|  **new KSK**  |        | pub+sign | pub+sign |  pub+sign |  pub+sign   | pub+sign | pub+sign | pub+sign | pub+sign |
|  **stand-by KSK**  |          |   pub    |   pub    |   pub    |   pub    | pub | pub | pub | pub |


Time schedule for case 3:

|           |  slot 1  |  slot 2  |  slot 3  |  slot 4  |  slot 5  |  slot 6  |  slot 7  |  slot 8  |  slot 9  |
|-----------|----------|----------|----------|----------|----------|----------|----------|----------|----------|
| **old KSK** | pub+sign | pub+sign | pub+sign | pub+sign | pub+sign | Revoke+sign | |     |          |
|  **new KSK**  |        | pub+sign | pub+sign |  pub+sign |  pub+sign   | pub+sign | pub+sign | pub+sign | pub+sign |
|  **stand-by KSK**  |        | pub | pub |  pub|  pub | pub | pub | pub | pub |
| **old ZSK** | pub+sign | pub+sign | pub+sign | pub+sign | pub+sign | pub+sign  | |     |          |
|  **New ZSK**  |        | pub+sign | pub+sign |  pub+sign |  pub+sign   | pub+sign | pub+sign   | pub+sign  | pub+sign  |


Time schedule for case 4:

|           |  slot 1  |  slot 2  |  slot 3  |  slot 4  |  slot 5  |  slot 6  |  slot 7  |  slot 8  |  slot 9  |
|-----------|----------|----------|----------|----------|----------|----------|----------|----------|----------|
| **old KSK** | pub+sign | pub+sign | pub+sign | pub+sign | pub+sign | Revoke+sign |   |     |          |
|  **new KSK**  |        |      | pub+sign |  pub+sign |  pub+sign   | pub+sign | pub+sign | pub+sign | pub+sign |
|  **new KSK**  |        |      | pub |  pub |  pub | pub | pub | pub | pub |
| **old ZSK** | pub+sign | pub+sign | pub+sign | pub+sign | pub+sign | pub+sign |  sign |     |          |
|  **New ZSK**  |        | sign | pub+sign |  pub+sign |  pub+sign   | pub+sign | pub+sign  |  pub+sign | pub+sign  |


## Rollback consideration

It might be interesting to test a rollback, in case a rollover would fail.

It is unlikely that an error occurs while still using the old algorithm for
signing when new key/algorithm is added. If this happens, then we can simply 
remove the new algorithm and its signature.

If an problem happens after changing to the new key and algorithm, we can go back to
the old key and algorithm before we set the old KSK with the "revoked" flag set. If this
happens, we will roll back to remove the new algoritm and key.

If a problem happens right after we publish the old KSK with the "revoked"
flag set, we should remove the revoked old KSK and its signature ASAP. Old KSK 
is not revoked in validators that have not observed the revoked old KSK. For those 
validators already observed the revoked old KSK and failed, resolver operators 
may need to update their configurations manually to fix the problem. 
This will be announced on the Yeti Discuss list as well as on the 
Yeti website.

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

## Consideration of Stand-by Keys

Defined in rfc6781#section-4.2.4, Stand-by keys are keys that are 
published in your zone but are not used to sign RRsets. There are 
two reasons why someone would want to use stand-by keys.  One is to 
speed up the emergency key rollover. The other is to recover from a 
disaster that leaves your production private keys inaccessible.

As ECDSA saves more space in the DNS response, it is worth of 
considering testing the Stand-by keys for new algorithm, by 
rolling the algorith with two KSKs, one is for signing and 
another for stand-by key. In the timelines for case 1, 2, 3 and 4 
for exmaple, every time slot when new key is introduced, 
a stand-by key is introduce without signing.  


