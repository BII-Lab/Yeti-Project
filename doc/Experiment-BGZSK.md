Big ZSK Experiment
==================
The Big ZSK experiment is designed to test operating the Yeti root
with a 2048-bit ZSK.

RSA 1024 is no longer recommended for cryptography. At some point the
ZSK needs to be made longer. Common practice is to adopt 2048 bits
keys.

VeriSign gave a presentation at the DNS-OARC 24th workshop, announcing
that they will be increasing the root zone ZSK from 1024 bits to 2048
bits in 2016:

https://indico.dns-oarc.net/event/22/session/4/contribution/14/material/slides/0.pptx

Yeti should change to RSA 2048 for ZSK and observe the results. If the
response size is greater than 1280 bytes it is likely that increased
TCP will be observed from priming queries.

Given that this is merely an extension of existing key length, and
that the KSK is already signed with the same algorithm and key length,
we propose not to require and lab test for this experiment.

This experiment does not require any specific changes on the part of
the Yeti root operators or the Yeti resolver operators.


Scope of Test
=============
This experiment will test the behavior of the Yeti root servers and
resolvers when we have a 2048-bit ZSK.


Experiment Plan
===============
Each of the three Yeti Distributors will change their ZSK from 1024
bits to 2048 bits. They will use the normal ZSK roll to do this. The
entire roll will take 12 days.


Rollback Procedures
===================
If a need to rollback is identified, we will roll to a new 1024 bit
ZSK for all Yeti Distributors.

If there is a rollback we will announce it to the Yeti Discuss list as
well as on the Yeti website.


What to Measure
===============
We are currently capturing questions at many root servers. We should
also change our capture scripts so that they also capture responses.

Since these measurements are occuring at all times, we do not need to
add any more caputures. We should look monitor the traffic before and
after we lengthen the ZSK to see if there are any changes, such as a
drop off of packets or a increase in retries.

We set up checks for the MZSK experiment to confirm that we can lookup
and validate a range of zones, using both BIND 9 and Unbound. We will
keep these in place for the BGZSK experiment.

The size of answers will increase, but we do *NOT* expect the average
response to fragment. Even a relatively large delegation will be less
than 1000 bytes (an example may be .INFO queries). Even so, we will
monitor possible impact by using RIPE Atlas measurements to measure
some key delegation queries.


Timeline
========
This experiment is relatively simple, and requires little preparation.

We can do preparation and start rolling in the new key on 2016-05-09
(Monday). This aligns well with the current ZSK timings for BII, where
the ZSK is scheduled to become inactive on 2016-05-11.

TISF would start rolling on 2016-05-13, and WIDE on 2016-05-17.


Report Format
=============
Once the BGZSK experiment is complete, we will produce a final report.

This will include the motivation and actions taken, as well as any
observations made during the experiment. The results of traffic
analysis will be included, along with a conclusion.
