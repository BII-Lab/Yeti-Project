
# Charter for Yeti DNS Project Phase-2

## Background and Motivation

“One World, One Internet, One Namespace” is the essence for the success of today’s Internet. The top level of the unique identifier system, the DNS root system, has been operational for nearly 30 years. It is pivot to make the current Internet useful. So it is considered somewhat ossified for stability reasons. It is hard to test and implement new ideas evolving to a more advanced level to counter challenges. To benefit the Internet development as a whole, Yeti Project was founded to build a parallel experimental live IPv6 DNS root system to discover the limits of DNS root name service and deliver useful technical output. As one important deliverable, [RFC8483](https://tools.ietf.org/html/rfc8483) documents the framework of Yeti testbed, experiments performed, operational experiences as well as future work consideration. (More information on previous work on Yeti project can be found in RFC8483.)

Recent years as the rise of concerns on DNS privacy [RFC7626](https://tools.ietf.org/html/rfc7626), Internet governance and High resilience of DNS, thoughts of decentralizing DNS Authority are getting popular. The idea of sharing control over the root was firstly discussed and proposed in ICANN Identifier Technology Innovation Report for ICANN's strategic planning in 2014 [[ITI2014]](https://www.icann.org/en/system/files/files/iti-report-15may14-en.pdf). There were some discussion of a "masterless" approach toward a solution.  [RFC8324](https://tools.ietf.org/html/rfc8324) suggests it should be possible to remove the technical requirement for a central authority over the root for next-generation DNS. It gives us motivation to revisit the current technical attention from the community and upgrade Yeti Root to "higher" level by introducing the properties of decentralization and fault-tolerance in next phase.

## The Goals of Yeti DNS Project in Phase-2

The goals of the Yeti DNS Project in Phase-2 are:

* Continue to serve the role as a live research testbed project to allow new experiments and proposals on DNS root.
* Solicit input from Yeti community to identify technical issues and concerns of centralized DNS root, determine solutions or workarounds to those issues.
* Solicit discussions and documentation of the issue and opportunities in Yeti Root operation in IPv6-only network, and of the resulting innovations.
* Develop guidelines for the operation of Yeti Testbed and services and for the administration of Yeti root zone. 
* Provide a good platform of communication and coordination from different stockholders in the scope of DNS and Root

It is worth confirming again that Yeti is a live testbed not for production network. And Yeti is **NEVER providing alternate name space**.

## Research Challenges

Although there are currently intensive research in literatures and development taking place around decentralized applications, the problem and challenge of decentralized infrastructure for DNS root is receiving relatively less attention. Some of these challenges include: 

* Scalability problem preventing decentralized infrastructure of DNS root services from achieving global scale
* Dirty slate or clean slate approaches to achieve a decentralized infrastructure for Yeti root
* Interaction and interoperability with existing DNS authoritative and recursive servers in DNSSEC context 
* Signing scheme among a group of signers in decentralized communication settings
* Consensus algorithms for specific scenarios of Yeti root
* Design and implementation of one or more proposal for Yeti Root systems
* Deployment and operation of one or more actual implementations in Yeti Testbed

## Organization

Yeti DNS Project is a open and volunteering project. We encourage self-sponsored participants to join this project with your servers, resolvers and insight to any technical discussion.

Yeti DNS Project provides an open forum for the exchange and analysis of DNS Root-related research.  Work both inside and outside Yeti is welcome,but those based on implementation experience is given preference. 

Yeti DNS Project uses an [open mailing list](http://lists.yeti-dns.org/mailman/listinfo/discuss) as the main collaboration tool, and will hold regular several f2f meetings per year. Yeti DNS Project will meet at least once per year at IETF meetings but will also reach out to other communities and hold meetings at their respective events such as conferences, project or standards meetings etc.

Yeti will outreach and coordinate with other International groups such as IETF DNSOP WG, IRTF DINRG, ICANN RSSAC, and regional organizations etc.


