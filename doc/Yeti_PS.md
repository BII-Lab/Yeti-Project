## Problem Statement 

Some problems and policy concerns over the DNS Root Server system stem from unfortunate centralization from the point of view of DNS content consumers. These include external dependencies and surveillance threats. 

* External Dependency. Currently, there are 12 DNS Root Server operators for the 13 Root Server letters, with more than 400 instances deployed globally. Compared to the number of connected devices, AS networks, and recursive DNS servers, the number of root instances is far from sufficient. Connectivity loss between one autonomous network and the IANA root name servers usually results in loss of local service within the local network, even when internal connectivity is perfect. Also this kind of external dependency will introduce extra network traffic cost when BGP routing is inefficient.

* Surveillance risk. Even when one or more root name server anycast instances are deployed locally or in a nearby network, the queries sent to the root servers carry DNS lookup information which enables root operators or other parties to analyize the DNS query traffic. This is a kind of information leakage which is to some extent not acceptable to some policy makers.

There are some technical issues in the areas of IPv6 and DNSSEC, which were introduced to the DNS Root Server system after it was created, and also when renumbering DNS Root Servers.

* Currently DNS mostly relies on IPv4. Some DNS servers which support both A & AAAA (IPv4 & IPv6) records still do not respond to IPv6 queries. IPv6 introduces larger IP packet MTU (1280 bytes) and a different fragmentation model. It is not clear whether it can survive without IPv4 (in an IPv6-only enviroment), or what the impact of IPv6-only environment introduces to current DNS operations (especially in the DNS Root Server system).

* KSK rollover, as a procedure to update the public key in resolvers, has been a significant issue in DNSSEC. Currently, IANA rolls the ZSK every six weeks but the KSK has never been rolled as of writing. Thus, the way of rolling the KSK and the effect of rolling keys (including both ZSK and KSK) frequently are not yet fully examined. It is worthwhile to test KSK rollover using RFC5011 to synchronize the validators in a live DNS root system. In addition, currently for the ZSK 1024-bit RSA keys are used, and for the KSK 2048-bit RSA keys are used. The effect of using key with more bits has never tested. A longer key will enlarge DNS answer packets with DNSSEC, which is not desirable. It is valuable to observe the effect of changing key bit-lengths in a test environment. Different encryption algorithms, such as ECC, are another factor that would also affect packet size.

* Renumbering issue. Currently Internet users or enterprises may change their network providers. As a result their Internet numbers for particular servers or services, like IP address and AS numbers, may change accordingly. This is called renumbering networks and servers. It is likely that root operators may change their IP addresses for root servers as well. Since there is no dynamic update mechanism to inform resolvers and other internet infrastructure relying on root servic of such changes, the renumbering issue of root server is a fragile part of the whole system.

Based on the problem space there is a solution space which needs experiments to test and verify in the scope of the Yeti DNS project. These experiments will provide some information about the above issues. 

* IPv6-Only Operation. We are try to run the Yeti testbed in pure IPv6 environment. 

* Key/Algorithm rollover. We are going to design a plan on Yeti testbed and conduct some experiment with more frequent change of ZSK and KSK.

* DNS Root Server renumbering. We may come up with a mechnism which dynamically updates root server addresses to hint file; this is like another kind of rollover.

* More root servers. We are going to test more than 13 root name server in Yeti testbed and to see "how many is too many".

* Multiple zone file editors. We will use IANA root zone as a source of zone info. Each of BII, TISF, and WIDE modifies the zone independantly at only its apex. Some mechinisms will be coined to prevent accidental mis-modificaiton of the DNS Root zone. In addition we may implement and test “shared zone control” ideas proposed in the ICANN ITI report from 2014. ICANN ITI report:   https://www.icann.org/en/system/files/files/iti-report-15may14-en.pdf

* Multiple zone file signers. To discover the flexibility and resiliency limits of Internet root zone distribution designs, we can try multiple DMs with one KSK and one ZSK for all, and we can try multiple DMs with one KSK for all and one ZSK for each.

## We are not

* We **never and ever try to create and provide alternate name space**. Yeti DNS project has complete fealty to IANA as the DNS name space manager from the beginning of its conception. Any necessary modifications of the current IANA zone (like the NS records for "." ) will be dicussed publicly and given a clear reason. 

* We are not going to develop or expriment with alternative governance models, regarding the concern arised in many occasions that a certain TLD (mostly ccTLD) will be removed intentionally as an additional option for punishment or sanction from USG to against its rivals. It maybe discussed or studied by different projects, but not Yeti. In Yeti we keep the same trust anchor (KSK) and the chain of trust to prevent on-path attacks and distribute root services based on the current model.
