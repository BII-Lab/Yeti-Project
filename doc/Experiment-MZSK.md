Multi-ZSK Experiment
====================
The Multi-ZSK experiment is designed to test operating the Yeti root
using more than a single ZSK. The goal is to have each distribution
master (DM) have a separate ZSK, signed by a single KSK. This will
allow DM to operate independently, each maintaining their own key
secret material.

The preliminary, lab-research has been completed. This experiment does
not require any specific changes on the part of the Yeti root
operators or the Yeti resolver operators.

http://lists.yeti-dns.org/pipermail/discuss/2015-October/000269.html

Scope of Test
=============
This experiment will test the behavior of the Yeti root servers and
resolvers as we have multiple ZSK, both during normal operation and
during rollover.

We will not change the algorithm used, the key lengths, or the
timings. While interesting, those should be done as separate
experiments.

Changes to Synchronization Protocol
===================================
The current Yeti Distribution Master (DM) synchronization protocol
shares both the private and public keys for the KSK and ZSK of the
root. Since we want to test a setup without sharing any secret
material, the sychronization method will need to be changed.

The setup that we should mimic is one where the ZSK are signed
via some other mechanism by the KSK. This is similar to the IANA key
signing ceremony. We do not need to actually perform any kind of
signing ceremony, just build a system that allows it.

Changes:

1. Remove the KSK secret key from the synchronization
   The KSK secret key will be kept by each DM operator to simplify
   rolling out new ZSK.

2. Remove the ZSK secret keys from the syncronization
   The secret portion of each ZSK will be kept by a single DM
   operator, and not published anywhere.

3. Separate each DM operator ZSK into a separate directory
   This is not strictly necessary, but it can help to be sure which DM
   operator is responsible for with ZSK.

4. Update zone generation software
   Each DM operator needs to update their zone generation software to
   use their private ZSK to sign the root zone, as well as including
   the signatures from the KSK.

Experiment Plan
===============

## Phase 1
In the first phase, we confirm that using multiple ZSK works in the
wild. We will insure that using the maximum number of ZSK continues to
work. Here one of the DM (BII) will create and add 5 ZSK using the
existing synchronization mechanism. (If all 3 ZSK are rolling then we
have 6 total. To get this number we add 5.)

<<Davey: add 5 ZSK pairs or just 5 ZSK public key? They will not be 
active during the whole Phase 1 experiment, right?>>

Since we will use the existing synchronization mechanism(TODO: give a 
like to existing SYN Mechnisom), all DM will sign using the previous ZSK. 
The 5 additional ZSK are there merely to test client behavior. We can 
set the activation date far in the future so they are never actually used.

Once we confirm that traffic continues to work, we can remove 3 of the
ZSK, leaving us with 3 ZSK which we will use for the start of phase 2
of the experiment.

<<Davey: the current rutine code of three DMs may not support contain all 6 
Public ZSK into the root zone. We should double check with Kato and Paul>>

## Phase 2
In the second phase, we separate the management of the ZSK so that
each DM will create and publish separate ZSK. For this phase, the
modified zone generation software mentioned above must be in place.

During the second phase, there are two specific things to test:

1. Rolling a ZSK (4 ZSK total)
   In this part, we perform a key roll for a ZSK. This will mean that
   there will be 4 ZSK in the root. We expect everything to work
   normally, but the response to priming query will be slightly
   larger.

2. Rolling all ZSK (6 ZSK total)
   Since ultimately all DM should be able to roll their ZSK
   independently of the other DM, we want to test the scenario where
   all 3 DM are rolling their key at once. This means there will be 6
   ZSK in the root. Again, we expect everything to work normally, but
   the priming query response will be even larger.


Rollback Procedures
===================
In Phase 1 if we need to rollback, we remove all additional 5 keys and
revert to the original ZSK.

In Phase 2 if we need to rollback after starting the first ZSK roll,
we remove all additional ZSK and revert to the original
(pre-experiment) ZSK.

In Phase 2 if we start signing with the new ZSK and there are
problems, we revert to signing with the old (pre-experiment) ZSK.

In Phase 2 if the first ZSK roll is successful, but we need to
rollback after starting the second ZSK roll (where we roll all 3 ZSK)
then we revert to the rolled ZSK.

In Phase 2 if we start signing with the 3 new ZSK and there are
problems, then we revert to the rolled ZSK.

In all cases if there is a rollback we will announce it to the Yeti
Discuss list as well as on the Yeti website.


What to Measure
===============
We are currently capturing questions at many root servers. We should
also change our capture scripts so that they also capture responses.
This will give us a more complete picture of what the effects of the
MZSK are.

Since these measurements are occuring at all times, we do not need to
add any more caputures. However, we should look monitor the traffic
before and after we add ZSK to see if there are any changes, such as a
drop off of packets or a increase in retries.

We should run checks throughout the MZSK experiment to confirm that we
can lookup and validate a range of zones, using both BIND 9 and
Unbound, as well as a manual validator such as drill.

<<Davey: There are two measurements: one is for IPv6 DNS MTU test. 
By caculation, there will be 1400+ B packet for DNSKEY with signature. 
We can use atlas probes to dig DNSKEY +DNSSEC and measuren the packets 
loss and TCP transaction. The second is for DNSSEC validation under MZSK>>

Timeline
========
The parameters that restrict the times are covered in great detail in
RFC 7583.

We can introduce two ZSK at any time. Once the TTL expires for the old
DNSKEY these will be used. The current TTL is 6 days, and the time it
takes for all root servers to get a copy of the zone must also be
added. We can conservatively say that after 7 days all resolvers must
be using the three ZSK.

After we verify that the 3 ZSK work, we can begin a ZSK roll. This
means introducing the new ZSK, waiting, switching to the new ZSK for
signing, waiting, and then removing the old signature.

Signatures on the RRSIG have a 1 day TTL, so we must wait 1 day before
removing the old signature, along with a delay to insure that the zone
has propagated to all root servers. 2 days should be enough.

The change to rolling all 3 ZSK at once can be done in exactly the
same way as rolling a single ZSK.


| Start Date | End Date   | Duration | Event 
|------------|------------|----------|--------------------------------------
| 2016-02-01 |            |          | Preparation 
|            |            |          | *PHASE 1 STARTS*
| 2016-02-15 |            |          | BII introduce 5 additional ZSK
|            |            | 2 weeks  | Monitor traffic 
|            |            |          | *PHASE 2 STARTS*
| 2016-02-22 |            |          | Introduce MZSK zone generation
| 2016-02-29 |            |          | Begin 1 ZSK roll (remove 3 ZSK, add 1 ZSK)
|            |            | 1 week   | Monitor traffic
| 2016-03-07 |            |          | Start signing with new ZSK
|            |            | 2 days   | Monitor traffic
| 2016-03-09 |            |          | Retire old ZSK
|            |            | 1 week   | Monitor traffic
| 2016-03-16 |            |          | Begin 3 ZSK roll (add 3 ZSK)
|            |            | 1 week   | Monitor traffic
| 2016-03-23 |            |          | Start signing with new ZSK
|            |            | 2 days   | Monitor traffic
| 2015-03-25 |            |          | Retire old ZSK (remove 3 ZSK)
|            |            | 1 week   | Monitor traffic
| 2015-04-01 |            |          | Champagne at DNS-OARC `:)`


Report Format
=============
Once the MZSK experiment is complete, we will produce a final report.

This will include the motivation and actions taken, as well as any
observations made during the experiment. The results of traffic
analysis will be included, along with a conclusion.
