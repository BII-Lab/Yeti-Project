# OnBoarding document for Yeti operator

**Scope**: The document will:

* Document the coordinator's operation procedue and checklist to onboard a new member 
* Document the basic technical requirement for Yeti root servers as well as the expectation of human resources as a Yeti root operator
* Specify the procedure of how to join and how to quit as yeti root operator
* Consider the case of one operator running multiple root servers
* Make some recommendations to Yeti root server operators.

## Procedure and checkelist of onborading a new member of Yeti Root operator

1. An application mail is received at the coordinator mailing list.
2. The BII coordinator (currently Davey) creates a ticket in Yeti RT system and takes ownership.
3. The BII coordinator will perform checks to verify that the applicant meets the technical requirements. These may be (should be) in an automated tool. The checks include, but are not limited to:

  * Verify that the hostname matches the IPv6 address given.
  * Verify that the IPv6 address can be reached via ICMPv6.
  * Warn if the IPv6 address is an EUI-64 address.
  * Verify that the DNS server can be queried via dig.
  * Verify the DNS serve can pull the root zone for BII DM (add to DM ACL)
  * Check anything missing for the application

  If the technical requirements are not met, then the BII coordinator will reply to the applicant via the ticket.
4. Each coordinator will need to review the request at this point and record the approvel decision or other suggestions in RT system. Coordinators can simply make a decision or discuss the application via RT system which also will be recorded in RT.
5. No matter all coordinators approved or not, then a comment will be added to the ticket, and the ticket will be resolved. BII Coordinator will issue an e-mail of the final decision sent to the applicant.
6. If the application is approved, BII coordinator adds the new name server to the list of Yeti roots, via the [**Yeti DM synchronization procedure**](https://github.com/BII-Lab/Yeti-Project/blob/master/doc/Yeti-DM-Sync.md). This means waiting for the IANA serial to advance to the desired serial number.
7. The BII coordinator verifies that all coordinators are producing the correct Yeti 
8. root zone after the publication serial.
8. The BII coordinator updates the Yeti root.hints file in the GitHub repository.
9. The BII coordinator updates the Yeti internal document which
   contains the details of all Yeti root operators. (Currently a
   Google doc which will be moved to Yeti Team tool，mattermost for example )
10. The BII coordinator updates the Yeti web page with the information about the new Yeti operator.
11. The BII coordinator sends a mail to the Yeti discuss and Yeti
   operators lists announcing the new operator, and inviting them tointroduce themselves.
12. The BII coordinator closes the ticket.
13. Champagne.

##Basic requirement for Yeti root server operator

To be come a Yeti root operator, you should know the basic requirements and our expectations:

* Understand the purpose and the goal of Yeti project
* Have some experience on operation of relevant DNS server(s)
* Software, hardware, and network requirements:

	* A dedicated server or VPS which only hosts the Yeti root zone
	* A stable and non-tunneled IPv6 network
	* A dedicated IPv6 address (EU64 IPv6 address is not recommended)
	* A dedicated domain name for the server which should have no A record attached to it.(We expect IPv6-only root)
	* Support DNSSEC.
	* Both the Yeti root server and its NS servers should be in a good health (stable for access)
	* The Yeti root server should not serve any other zone except yeti root zone
	
*Human resources commitment

Because it is a live testbed for root system experiment, so we do not expect any urgent configuration changes. However, the server cannot be fully on auto-pilot, due to experiments that will affect the distribution master servers and may require changes to the authority servers. Therefore, we expect authority operators to offer 24-hour response time to questions and outage notifications, and 72-hour response time for planned configuration changes. There is a Yeti health monitoring page : http://yeti-dns.org/yeti_server_status.txt which can indicate the status of yeti root servers.

Note: The coordinators of Yeti DNS project reserve the right to deny the application or remove an existing operator if they can not meet the basic requirements.

## How to join and how to quit

Regarding how to join Yeti as a root operator, there is a document https://github.com/bii-lab/Yeti-Project#how-to-join-yeti which describes the steps to apply and setup the server.

From the coordinators' side, to setup we need the following information:

* IPv6 address to serve (EUI-64 based address should be avoided).
FQDN of the server.
* IPv6 address used to pull the zone (this may be different from the service address, especially if the service is provided by multiple machines). This may be required by the ACL at the DMs.
* The software and version 
* VPS or physical machine
* E-mail address for each of the responsible persons.
* Responsible persons' PGP key (registered at pgp.mit.edu is preferable).
* If any operator want to quit for some reason, you should to send a mail to the coordinators 7 days in advance.

## Considerations in running multiple Yeti root servers by one operator

From both research and operational aspects it sounds OK, the only concerns are:

1) The diversity of system and network, and 2) The opportunity for future participants given 25 is our target number of of Yeti root servers (ideally 25 operator are from different countries and a various continents).

There is an agreement for a Yeti operator who would like to run **Additional root server**. A Yeti operator can apply additional root server only when:

* The number of Yeti root servers is less than the maximum number of roots in the Yeti testbed (currently 25),
* They meet the basic technical requirements for the additional server, and
* They provide the information of additional server, just like the initial server they operate.
* The domain name, IPv6 address, DNS software should reflect and introduce diversity. (It means different Domain name, IPv6 prefix, DNS software etc.)
* Note that coordinators reserve the right to reclaim the **Additional root server** in case no room for new Yeti root operator (given that there is a limit).


## Some recommendations to yeti root server operators

* To let people know more about you and your organiztion, please send us a link to us : "About us" page in your company website, or a dedicated page for yeti to introduce yourself.
* To be more active in Yeti community, please do pay attention and join the discussion of Yeti mailling list. 
* Now we do not have much traffic in our testbed in the early phase. It will be appreciated if you can introduce Yeti to the people/ universitiues/ IPv6 pilot/ research labs who may be insterestd to use yeti root services as experimental testbed.   
