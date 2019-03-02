# Yeti experiment plan for PINZ (Preserving IANA NSEC Chain and ZSK RRSIGs)

## Introductions

Yeti DNS Project takes the IANA root zone, and performs minimal changes needed to serve the zone from the Yeti root servers instead of the IANA root servers. The [Yeti-DM-Setup document](https://github.com/BII-Lab/Yeti-Project/blob/master/doc/Yeti-DM-Setup.md) describes what's the minimal changes is necessary and how it is done in Yeti DM. 

One change of DNSSEC is that the current Yeti root zone is signed by Yeti's key(ZSK and KSK) replacing all keys and signatures from IANA in the zone. However, it is proved that this change is not that "minimal" and the difference (by diff) between IANA root zone and Yeti root zone can be further reduced. It is proposed as a Yeti experiment which preserves IANA NSEC Chain and ZSK RRSIGs in Yeti root zone. The purpose of this experiment is to verify the capability of root zone including record-by-record signatures and respective keys based on current DNS protocol and implementation, and to verify whether it is workable without breaking DNSSEC validation in validating resolver.

This document describes in detail the operational steps to accomplish a Yeti experiment called PINZ (Preserving IANA NSEC Chain and ZSK RRSIGs). It is first introduced as an experiment proposal in [a Yeti blog post](http://yeti-dns.org/yeti/blog/2017/08/22/Preserving-IANA-NSEC-Chain-and-ZSK-RRSIGs.html) and a lab test was done for feasibility study. The steps to be performed are based on the experiment proposal, meetings of Yeti coordinator, and comments collected from Yeti participants.

## Preparation and considerations

There are mainly three parts for preparation and consideration for this experiment plan.

### The Changes in PINZ

To simply understand the changes made in PINZ, there is a table provided to compare the difference between current Yeti root zone with the zone in PINZ experiment. It is helpful for DM operators to prepare the system to generate new zone in PINZ.

Table 1. The changes made in PINZ Compared with current Yeti zone

| RR in the zone | Current Yeti zone  | PINZ Zone | 
|-----------------|--------------------|----------|    
| . SOA           |Yeti SOA            |No Change |
| . NS            | All Yeti's server  |No Change |
| . DNSKEY        | Yeti's Keys        |**Yeti's key +IANA ZSK** |
| . RRSIG SOA     | Signed by Yeti ZSK |No Change |
| . RRSIG NS      | Signed by Yeti ZSK |No Change |
| . RRSIG DNSKEY  | Signed by Yeti KSK |No Change|
| . RRSIG NSEC    | Signed by Yeti ZSK |**Signed by IANA ZSK** |
| TLD's RRSIG DS  | Signed by Yeti ZSK |**Signed by IANA ZSK** |
| TLD's RRSIG NSEC| Signed by Yeti ZSK |**Signed by IANA ZSK** |


Before the experiment, DM operators are required to develop a new routine (Python or Perl script) to apply the changes when generating a new root zone according to the experiment proposal. 

The example of diff result between IANA's zone and BII-DM's zone at SOA Serial 2018032601 is shown below:

<iframe style = "overflow-x:scroll" width=95% height="400px" src="http://yeti-dns.org/diff_iana_bii.txt" > </iframe>

The example of diff result between BII-DM's zone and WIDE-DM's zone at SOA Serial 2018032601 :

<iframe style = "overflow-x:scroll" width=95% height="400px" src="http://yeti-dns.org/diff_bii_wide.txt" > </iframe>


### PINZ Transition

Similar to ZKS rollover process, the transition to PINZ requires administrator to consider the fact that data published in previous versions of Yeti zone still lives in caches. For example the signatures of NSEC Chain and DS records saved from IANA root zone will meet the old DNSKEY RRSet which is still cached in Yeti's resolvers. 

As a result, it is important to design a transition plan for PINZ experiment, pretty similar to the Yeti ZSK rollover plan which follows the [Pre-Publish approach](https://tools.ietf.org/html/rfc6781#section-4.1.1.1) defined in [RFC6781](https://tools.ietf.org/html/rfc6781). The only difference is that the PINZ transition does not require a DNSKEY removal process suggested in [RFC6781](https://tools.ietf.org/html/rfc6781), because the Yeti ZSK will continue to sign the . SOA and . NS RRs. It means all Yeti keys and IANA ZSK will remain in the Yeti root zone unless any potential serious problem happens. 

Note that In case of serious failure taking down the system, a fall back mechanism will be triggered to roll the system back. The [Fallback Plan](https://github.com/BII-Lab/Yeti-Project/blob/master/doc/Experiment-PINZ.md#fallback-plan) is introduced later in this document.

Note that it is desired, according to Yeti DM operators, that the PINZ transition period avoids IANA-ZSK rollover and ZSK rollover of each DM. The ZSK rollover information is given as below:

* Next ZSK rollover time of IANA: TBD (communication)

* Next ZSK rollover time of BII: pre-publish at 2018042100 (and next rollover at 2018050500), activate in 3 days

* Next ZSK rollover time of WIDE: pre-publish at 2018041700 (and next rollover at 2018051700), activate in 3 days

## Experiment schedule 

PINZ transition can be simply divided into two phases:

### Phase A : Publication
According to The table 1, the first change made by PINZ is to publish IANA ZSK of the time into Root DNSKEY RRset. This phase is called Publication for Phase A. And it will last 10 days according to table 2. 

Phase A is successful when the new key is successfully configured in both server and resolver as a valid ZSK in DNSKEY RRset. And there is no identifiable systemic failure impacting DNSSEC validating servers and resolvers.

### Phase B : New RRSIGs

After Phase A, it is considered that all Yeti caches are updated with new key. It is time to replace Yeti's RRSIGs for TLD's DS and NSEC with RRSIGs signed by the new key. It is called New RRSIGs for Phase B. The end of Phase B currently is not defined. It could be a normal configuration of Yeti root testbed if there is no significant failure taking down the system. 

Phase B is successful when no operational issues remain after transition from current Yeti root zone to PINZ zone.

### Schedule 

There is a timeline for PINZ experiment in which one "slot" is 10 days long:

|           |  slot 1  |  slot 2  |  slot 3  |  slot 4,5,6,...  |
|-----------|----------|----------|----------|----------|
| Yeti ZSK  | pub+sign | pub+sign | pub+sign | pub+Sign (. NS/SOA/DNSKEY)|
| IANA ZSK|       | pub      | pub      | pub+ TLD's RRSIG NSEC/DS (Signed by IANA ZSk) |

The tentative time:

* **Starting Slot 2 on May 1st 2018.**

Note that WIDE and BII will make the DM system ready at 0700 UTC on May 1st waiting for next IANA serial to publish IANA ZSK.

* **Starting Slot 4 on May 21st 2018.**

Note that WIDE and BII will make DM system ready at 0700 UTC on May 21st waiting for next IANA serial to publish IANA RRSIG.

### Fallback Plan

Even though Yeti testbed does not have large-scale network, but for research purpose, it is worth considering and preparing a fallback plan, in case any unforeseen circumstances occur which cause very serious failures and can not be solved by (temporarily) disabling DNSSEC validation for small group of validating resolvers.  

According to the milestones in the experiment schedule, the beginning of Phase A (slot 2) and Phase B (slot 4) are the two failure points where fallback may happen.

*  If a problem arises during the slot 2 when IANA ZSK is Pre-publised in the Yeti root zone, the fallback plan is to simply un-publish that IANA ZSK from Yeti root zone, and continue signing with the current Yeti ZSK (one DM's ZSk). The experiment will be postponed for looking into what's wrong.
*  If a problem arises during the slot 4 when IANA's RRSIGs (DS/NSEC) are included replacing the RRSIG signed by Yeti ZSK, the fallback plan is simply to revert to signing NSEC RR and TLD's DS with Yeti ZSK. The IANA Key is still published in the root zone until some decision is made to remove it.

Note that there may be other corner cases which are not obvious right now. So it is worth doing the monitoring at high alert and report any issue ASAP.

## What to Measure 

As a Yeti experiment, generally we should capture weird and failing events with sufficient information to diagnose them. Logs and captured packets will be helpful. Specific to PINZ, there are mainly two expected events worth of measuring:

###1) DNSSEC validation failure

In lab test, we tested as a black box to check the RCODE of DNS response to query with DO bit. We also recorded the DNSSEC log to demonstrate whether it worked or not. So Yeti resolver operators can monitor in that way. If anything weird happens they can report the event to [Yeti discuss mailing list](mailto:discuss@lists.yeti-dns.org) with descriptions of the event and DNSSEC log.

```
31-May-2017 15:46:49.278 dnssec: debug 3: validating net/DS: starting
31-May-2017 15:46:49.278 dnssec: debug 3: validating net/DS: attempting positive response validation
31-May-2017 15:46:49.278 dnssec: debug 3: validating net/DS: keyset with trust secure
31-May-2017 15:46:49.278 dnssec: debug 3: validating net/DS: verify rdataset
(keyid=14796): success
31-May-2017 15:46:49.278 dnssec: debug 3: validating net/DS: marking as secure, noqname proof not needed
```

In the above DNSSEC log, the keyid 14796 is IANA ZSK. It's successful because the IANA ZSK is recognized and used for validation.

Note that it is also proposed that a small piece of script running on volunteer resolver and recording the event in a formal and unified format may help for analysis and statistic.

###2) Response size increase for DNSKEY query. 

Similar to the [monitoring on Yeti KSK rollover](http://yeti-dns.org/yeti/blog/2017/08/02/large-packet-impact-during-yeti-ksk-rollover.html), a monitoring on response size should be performed during the experiment. Although it can be foreseen and calculated by adding additional key, the monitoring is useful for providing extra information on the impact of PINZ experiment. 

## Notification to Yeti resolvers

Currently Yeti has hundreds of resolvers who send queries to Yeti root servers. Although we fully expect the change to occur without incidents. However, unforeseen problems may be beyond our control which may cause DNSSEC validation fail for some validating resolvers. So it needs more publicity and awareness of these changes in PINZ among Yeti community members before the kick off of the experiment.

One-month notify and warning in advanced is necessary for Yeti resolvers with mails and blog post introducing how the experiment will be performed as well as the impact.

One simple way to fix unforeseen problems on resolver side is to disable DNSSEC if any validation failure is noticed during the transition period (new RRSIG phase). 

## TBD

The plan is still under comments and reviews. Tentative data and schedule may be changed during the process. 

It is proposed that a small piece of script running on volunteer resolver and recording the event in a formal and unified format may help for analysis and statistic. If a monitoring tool can be developed before slot2 or slot4 it will help to achieve that purpose.
