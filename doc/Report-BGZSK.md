# Yeti Project Report: Big-ZSK Experiment (BGZSK)
## Version: 1.0
## Date: 2016-12-15

Introduction
============
Yeti DNS System is a live testbed for Root DNS Server System:

    https://yeti-dns.org/

In mid-2016, the Yeti project ran the Big ZSK (BGZSK) experiment,
designed to test operating the Yeti root with a 2048-bit ZSK.

RSA 1024 is no longer recommended for cryptography. At some point the
ZSK should be made longer. Common practice is to adopt 2048 bits keys.

VeriSign gave a presentation at the DNS-OARC 24th workshop, announcing
that they will be increasing the root zone ZSK from 1024 bits to 2048
bits in 2016:

https://indico.dns-oarc.net/event/22/session/4/contribution/14/material/slides/0.pptx

Yeti changed to RSA 2048 for ZSK and observed the results. The
expectation was that while signed replies will be larger, it was
unlikely that we would see increased truncation or fragmentation, as
most replies would still be less than 1280 bytes.

Given that this was merely an extension of existing key length, and
that the KSK was already signed with the same algorithm and key length,
no lab test was required for this experiment.

This experiment did not require any specific changes on the part of
the Yeti root operators or the Yeti resolver operators.

The BGZSK experiment proposal and more details were documented in
Experiment-BGZSK[1].

Experiment Protocol
===================
The Yeti project uses an experiment protocol, documented in
Experiment-Protocol[2]. The BGZSK experiment did not follow this
protocol. Normally there are:

1. Proposal
2. Lab Test
3. Yeti Test
4. Report of Findings

However, in the case of the BGZSK we decided that since the mode of
operation was so standard that a lab test would not be necessary. So
for the BGZSK experiment we simply followed:

1. Proposal
2. Yeti Test
3. Report of Findings

This document is the report of findings.

Project Timeline
================

## 2016-04-25

Shane Kerr sent a mail[3] to the Yeti discussion mailing list
proposing that Yeti conduct the BGZSK experiment.

## 2016-05-06

Shane Kerr sent a mail[4] announcing the start of the BGZSK
experiment.

## 2016-05-09

BII 2048-bit ZSK published, with the old 1024-bit ZSK still there.

## 2016-05-11

BII 2048-bit ZSK used for signing.

## 2016-05-12

TISF 2048-bit ZSK published, with the old 1024-bit ZSK still there.

## 2016-05-13

BII 1024-bit ZSK removed.

## 2016-05-14

TISF 2048-bit ZSK used for signing.

## 2016-05-16

TISF 1024-bit ZSK removed.

## 2016-05-17 

WIDE 2048-bit ZSK published, with the old 1024-bit ZSK still there.

## 2016-05-19

WIDE 2048-bit ZSK used for signing.

## 2016-05-21

WIDE 1024-bit ZSK removed.

## 2016-06-06

The experiment was concluded[5].

Observations & Results
======================
No operational issues were reported or discovered. The Yeti system
continued to work during all phases of the roll.

Analysis of Captured Packets
============================
Description of measurements

Conclusions
===========
Using a 2048-bit ZSK for the Yeti root works as expected.

Since the 2048-bit ZSK works and since the IANA also moved to a
2048-bit ZSK soon, the Yeti project has left it in place.

[1]: https://github.com/BII-Lab/Yeti-Project/blob/master/doc/Experiment-BGZSK.md
[2]: https://github.com/BII-Lab/Yeti-Project/blob/master/doc/Experiment-Protocol.md
[3]: http://lists.yeti-dns.org/pipermail/discuss/2016-April/000500.html
[4]: http://lists.yeti-dns.org/pipermail/discuss/2016-May/000556.html
[5]: http://lists.yeti-dns.org/pipermail/discuss/2016-June/000596.html

