# Welcome to the Yeti Project
------

"One World, One Internet, One Namespace" is the essence for the success of today's Internet. The top level of the unique identifier system, the DNS root system, has been operational for 25+ years. It is a pivot to make the current Internet useful. So it is considered somewhat ossified for stability reasons. It is hard to test and implement new ideas evolving to a more advanced level to counter challenges like IPv6-only operation, DNSSEC key/algorithm rollover, scaling issues, etc. Because changes to the current production system are not risk-free, and a large-scale testbed is necessary, on which extensive tests and studies of the impact can be carried out. It is possible to pre-evaluate such changes in a laboratory test, however, the coverage is limited. In order to make the test more practical, it is also necessary to involve users’ environment which is highly diversified, to study the effect of the changes in question. 
 
As a result the proposal of Yeti Project is formed which is aiming to build such a live environment. The basic idea is to build a parallel experimental live DNS root system to provide useful technical output with the existing production systems. Possible research agenda will be explored on this testbed covering several aspects but not limited to:

* IPv6-only operation
* DNSSEC key rollover
* Renumbering issues
* Scalability issues
* Multiple zone file signers

In addition measurement study will be done to create useful analysis as output of Yeti Project.

Participants will be invited into Yeti Project which is hopefully helpful for their own interests. We would like to invite some interested parties in this community, like the research labs of universities and institutes. We also hope Yeti Project can gain the support from vendors, for example, the DNS software implementers, Developers of CPE devices & IoT devices, middlebox developers who can test their product and connect their own testbed into Yeti testbed. It is expected that the activity of Yeti Project could have good input to the DNS related industry, which will finally make them ready for advanced DNS and Root services.  

*NOTE THAT THIS PROJECT NEVER INTENT TO REPLACE CURRENT OPERATIONAL ROOT DNS SYSTEM.　REGULAR DNS SERVICES MUST NOT DEPEND ON THE TESTBED.*

# How to Join Yeti
------

Please contact <discuss@lists.yeti-dns.org> if you wish to ask question and receive latest update in the Yeti project.

Below are details about the different ways of joining the effort.

 Joining Yeti as a Yeti Root Server Operator
-------------------------------------------
To run a Yeti root server, you need a server with good IPv6 Internet access, a dedicated domain of the root server which is configured as a slave to the Yeti distribution masters (DM). There are a few steps to Join Yeti as a Yeti root server operator.

Step 1: Application 
Please send a mail to coordinators@lists.yeti-dns.org with your basic contact information, short introduction or a short declaration to join Yeti Project as a volunteer authority server. Most importantly send a domain name and IPv6 address of the new root server which is to be added into the apex NS  RRset of our root zone. 

Note that even though we publish strictly iana information for TLD data and metadata, it's necessary for us to replace the apex NS RRset.  Once we verify that your server is operational we will add it to the apex NS RRset, and we will add you and your designated colleagues to the operators@ mailing list.

Step 2: Root server setup
Configure the root server as a slave to the Yeti DM. you can add the following script to the configuration file of your root server. 

masters yeti-dm {
	240c:f:1:22::7;         	# bii
	2001:200:1d9::53;    	# wide
	2001:559:8000::7;    	# tisf
};
Afterward, please send a mail to coordinators ML to notify it is done.

Step3:Monitoring system setup
For the purpose of experiment and measurement study,we require each root server operator to capture DNS packet on DNS servers and save as pcap file, then send to our storage server. <<Regarding the data sharing issue, please turn to the data sharing document of YETI Project>>

Please read the following link how to setup and join the YETI monitoring system
https://github.com/BII-Lab/Yeti-Project/blob/master/script/monitor-external/README.txt 

This script submits DNS packet via rsync+ssh. Note that it uses ssh Pubkey Authentication, so user should provide ssh public key via mail to the coordinators; 

Joining Yeti as a Resolver Operator
-----------------------------------
We encourage people running resolvers to join the project. These should be used for real-world queries, but for informed users in non-critical environments.

To join the Yeti project as a resolver operator, you need to have a working DNS resolver with IPv6 support. You need to update your "hints" file to use the Yeti root servers instead of the IANA root
servers. The current "hints" file can be found here: 
https://raw.githubusercontent.com/BII-Lab/Yeti-Project/master/domain/named.cache  

in the purpose of some experiment, we need information and feedback from client side, so we encourage resolver operator to register it mail address for technical assistance, Yeti  testbed changes or experiments coordination. if you setup your recursive server linked with Yeti root server, please contact coordinators@lists.yeti-dns.org .

3. Joining Yeti as a Researcher
----------------------------
Researchers are encouraged to join the Yeti discussion list:

http://lists.yeti-dns.org/mailman/listinfo/discuss 

Potential experiments or analysis can be discussed there.

Confidential inquiries can be sent to <coordinators@lists.yeti-dns.org>.

FQA :

Q：The requirement for  the machine (apparently, a VPS could be enough?)
A: A VPS is OK. The experiments we expected so far (described in the webpage) are not strongly related to computing and mem capacity of server , but networking connectivity matters.
 
Q: How about its connectivity?
A: IPv6 networking environment is important to our experiment especially IPv6 DNS MTU problem study. We need native, non-tunneled IPv6 connectivity, either as a customer of a national or international backbone network, or as a multi-homed network who peers aggressively.
 
Q: Human resources commitment for root server operator. 
A: Well, this is a good question. Before we announce the project, three Initiators (WIDE, TISF and BII) had a basic consensus on the commitment to this scientific project. Because It is not for production network, so we do not expect any urgent configuration changes. however the server cannot be fully on auto-pilot, due to experiments that will affect the distribution master servers and may require changes to the authority servers. therefore, we expect authority operators to offer 24-hour response time to questions and outage notifications, and 72-hour response time for planned configuration changes. We are no-profit, no exchange of money, only for public and technical interest. So we would like to invite qualified contributors who are willing to share the same interest and commitment with us.

Q: Is there Data usage policy in Yeti project?
A: Please turn to the data sharing document of Yeti DNS project. Basically, the data is for scientific use which means the data with personal information or with privacy concern is not expected to join Yeti experiment. on another hand, every participant who want to get access to the data should make a public statement of using Yeti data to protect privacy, and do not publish the raw data.
