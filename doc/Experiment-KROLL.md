Yeti KSK Rollover Experiment (KROLL)
====================================
The Yeti KSK rollover experiment is designed to perform a single KSK
roll for the Yeti root and observe the effects.

The Yeti root KSK rollover will use the KSK Double-DS rollover as
described in RFC 6787, although without publishing the DS in the
parent (since the root has no parent):

https://tools.ietf.org/html/rfc6781#section-4.1.2

It will follow the timings described in RFC 5011, to allow resolvers
to automatically update their trust anchors.

https://tools.ietf.org/html/rfc5011

Note that this is _NOT_ the same as the proposed KSK rollover that
ICANN is going to use for the IANA root. This experiment covers a
simple KSK roll. An experiment to duplicate conditions similar to the
ICANN roll will be performed later.


Description of the Yeti root KSK 
================================
The Yeti root KSK uses the RSA/SHA-256 algorithm with a 2048 bit key,
the same as the IANA root KSK. It is generated on software, and stored
on systems secured with similar security to enterprise computing
resources; no HSM is used, and no documented procedures exist for
access or updating the KSK.


Experiment Plan
===============
The basic plan is "do it and see what happens".

The approach is:

1. Generate a new KSK. This will be placed into the DM synchronization
   repository. The DM synchronization is described here:

   https://github.com/BII-Lab/Yeti-Project/blob/master/doc/Yeti-DM-Sync.md

   This KSK will appear in the Yeti root, but not be used for signing.

2. Wait 30 days.

3. Set the "revoked" flag on the old KSK and place that into the DM
   synchronization repository. The ZSK will be signed with the old and
   the new KSK.

4. Wait 30 days.

5. Remove the old KSK at each distribution master.


Rollback Procedures
===================
It is unlikely that an error occurs while still using the old KSK for
signing. If this happens, then we can simply remove the new KSK.

If an problem happens after changing to the new KSK, we will not be
able to simply go back to the old KSK, since it will have the
"revoked" flag set. Depending on the nature of the failure, resolver
operators may need to update their configurations manually to fix the
problem. This will be announced on the Yeti Discuss list as well as on
the Yeti website.


What to Measure
===============
We are currently capturing questions at many root servers. We should
also change our capture scripts so that they also capture responses.

Since these measurements are occurring at all times, we do not need to
add any more captures. We should look monitor the traffic before and
after we add the new KSK to see if there are any changes, such as a
drop off of packets or a increase in retries.

We set up checks for the MZSK experiment to confirm that we can lookup
and validate a range of zones, using both BIND 9 and Unbound. We will
keep these in place for the KROLL experiment.

The size of DNSKEY lookups for the root zone will increase, but it
will still be less than during the MZSK experiment, when we had 7
DNSKEY at one time for the root.


Timeline
========
Since the Yeti DNS Project already has all the necessary
infrastructure for this experiment, it is straightforward, requiring
no preparation in advance.

We can do preparation and add the new KSK on 2016-07-10 (Sunday).

We can switch signing to the new KSK on 2016-08-12 (Monday), which is
more than 30 days later. This will also set the revoked bit on the old
KSK.

The old KSK will be totally removed on 2016-09-14 (Thursday), which is
more than 30 days after the revoked bit is set.


Report Format
=============
As with prior experiments, when the KROLL experiment is complete we
will produce a final report.

This will include the motivation and actions taken, as well as any
observations made during the experiment. The results of traffic
analysis will be included, along with a conclusion.


Acknowledgments
===============
Thanks to 龚道彪 (Kevin) at BII for the initial documentation of the
KSK roll process.
