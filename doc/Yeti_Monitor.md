# Yeti Monitor


Currently Yeti testbed lacks sufficient information to reflect the status 
of Yeti operation, in aspect of availability, consistency and performance.
It also lacks tools to measure the result of experiments of like introducing 
more root server, KSK rollover, Multi-ZKSs etc. There is a monitoring work done in [Yeti-Health-Monitoring](https://github.com/BII-Lab/Yeti-Project/blob/master/doc/Yeti-Health-Monitoring.md). 
and displayed a simple page in http://yeti-dns.org/yeti_server_status.txt. 

Note that there are may be another type of Yeti monitoring for specific experiment.
We refer it as to tools for measurement study which is out of the scope of this 
document and will covered by specific experiment design.

## Monitoring requirement 

### 1. Yeti Distribution Master 

**Availability**

* Ping6 (or traceroute6) all the servers periodically (3600 sec)
* Send queries to all the DM server periodically (3600 sec)
* Ask for zone transfer to test AXFR/IXFR periodically (3600 sec)
* TTL, dig query response time

**Consistency**
Send queries to each DM to check the consistency in following aspects:
* SOA(SERIAL, MNAME, RNAME,...)
* DNSKEY RRset
* NS RRset
* Root zone (TLD data)  
<We know that Paul's zone omits "unnecessary" glue, so we need to make sure that we do NOT check for this. -Shane> 

## 2. Root server 

###Availability 

* Ping6 (or traceroute6) all the servers periodically (3600 sec)
* Ping6 all the servers periodically (3600 sec)
* send queries to all the server periodically (3600 sec)
* Use a set of Atlas probes to query, and count the ratio of unanswered query.(We can use DomainMON)
* TTL, dig query response time

**Consistency**
Send queries to each DM to check the consistency in following aspects:
* SOA(SERIAL, MNAME, RNAME,...)
* DNSKEY RRset
* NS RRset
* Root zone (TLD data)  

**Authoritative Server function check**

* EDNS0 support or not
* DNSSEC support or not
* Allow AXFR/IXFR or not
* IPv6-only or not
* A/AAAA support or not

**Query taffic analysis (From DSC page?)**
* Ratio of TCP and UDP query
* Statistics of lenght of response
* Ratio of A and AAAA query

Davey: How about provide a page with some test scripts or commands 
to ask anyone try to execute locally and upload their result? Like 
What OARC dose for reply-size-test : https://www.dns-oarc.net/oarc/services/replysizetest 

### 3. other system in Yeti project

**DSC/data collecting system**

	Monitor root server upload data or not
### Mail system
	
	http/https,up or down, debug information available  
### Tickets system
	
	http/https,up or down, debug information available  
### Yeti web server
	
	http/https,up or down, debug information available  

## Yeti Monitoring Design

In this section we plan to design a monitoring tool for Yeti testbed according to 
the monitoring requirement in previous section. Basically Yeti Monitor serve two 
purpose : 1) Monitor the status of Yeti testbed and build event alert for operator 
of Yeti testbed; 2)Give friendly visualization for audience who are interested to 
know the general Yeti status.

### Yeti Monitoring page

* Yeti Root Server Status Check

Provide A visualization like https://atlas.ripe.net/domainmon/yetiroot./85/f1gFuyhM/ 
  
There are some TODO tasks to upgrade this page with more option(free probe selection, 
adding/deleting servers problem alert to Yeti operation team). Shane will follow up 
this thread with RIPE Atlas people.
    
* Zone consistency check (15 root server and DMs)

additional section in priming response.
	
*  Server function check for (for 15 root server)

EDNS0 support or not, DNSSEC support or not, Allow AXFR/IXFR or not, IPv6-only or not, A/AAAA support or not

* Packet size check
 
Response to Priming+DNSSEC, DNSKEY+DNSSEC, (print the dig response)

* Compareation with IANA system ( diff IANA and Yeti unsigned root zone file)

### Yeti Event Alert 

* Event Alert for Yeti root server failure.

Combine Atlas status check with Nagios to build some alert of failure of server availability. Automatically send mails to contact of yeti server operator.

* Event Alert for Yeti consistency failure 
	
According to the status check of SOA, ZSK, KSK, NS RR. Automatically send mails to Yeti distributor mailing list.

* Event Alert for Yeti supporting system

Web, Mailing list, tickets, DSC server, 15 server uploading status

