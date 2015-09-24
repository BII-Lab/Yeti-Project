Background
==========
Each Yeti Distribution Master (DM) needs to publish the same root zone
file as the other DM. In order to do this, the DM need to synchronize
the information used to produce and publish the root zone. This
includes:

* the list of Yeti root servers
* the ZSK used to sign the root
* the KSK used to sign the root
* the serial when this information is active


Theory of Operation
===================
Each DM operator runs a Git repository, containing files with the
information needed to produce the Yeti root zone.

When a change is desired, a DM operator updates the local Git
repository. A serial number in the future is chosen for when the
changes become active.

The DM operator then pushes the changes to the Git repositories of the
other two DM operators. When the serial of the root zone passes the
number chosen, then the new version of the information is used.


Details of Git Setup
====================
Each DM operator runs a Git repository, with SSH access.

username: yeticonf
repository: dm

The SSH keys for the account include one from all three DM operators.

Any firewall must allow access from:

  2001:559:8000::/48      # tisf
  240c:f:0:ffe7:1::11/128 # bii
  2001:200::/32           # wide

Only the master branch is used.


Details of Files
================
The Git repostitory has the following files:

* yeti-root-servers.txt
* iana-start-serial.txt
* yeti-root-ksk.key
* yeti-root-ksk.private
* yeti-root-zsk.key
* yeti-root-zsk.private

The `yeti-root-servers.txt` file contains one line per Yeti root
server, which has the server name and IPv6 address, like this:

    bii.dns-lab.net.            240c:f:1:22::6
    yeti.bofh.priv.at.          2a01:4f8:161:6106:1::10
    yeti.ipv6.ernet.in.         2001:e30:1c1e:1::333
    dahu1.yeti.eu.org.          2001:4b98:dc2:45:216:3eff:fe4b:8c5b
    ns-yeti.bondis.org.         2a02:2810:0:405::250
    yeti-ns.ix.ru.              2001:6d0:6d06::53
    yeti-ns.tisf.net.           2001:559:8000::6
    yeti-ns.wide.ad.jp.         2001:200:1d9::35
    yeti-ns.conit.co.           2607:ff28:2:10::47:a010
    yeti-ns.as59715.net.        2a02:cdc5:9715:0:185:5:203:53
    yeti-dns01.dnsworkshop.org. 2001:1608:10:167:32e::53

The `iana-start-serial.txt` file contains the serial in the SOA of the
IANA root zone when to start using the data:

    2015092300

The `yeti-root-ksk.private`, `yeti-root-ksk.key`,
`yeti-root-zsk.private`, and `yeti-root-zsk.key` are in the format the
BIND 9 `dnssec-keygen` uses.


Operations
==========
There are a number of operations that the distributors need to
perform.

Change Data
-----------
The various operations that change data are:

* Add/delete/renumber/rename Yeti root server
* Add a new ZSK
* Add a new KSK

The logic behind any of these is:

1. Check to make sure that no operation is pending.
2. Update the appropriate file in the directory.
3. Update the `iana-start-serial.txt` file with a serial 2 days in the
   future.
3. "git add"/"git commit"/"git push" of the file(s) and the
   `iana-start-serial.txt` file.

To add a Yeti root server you add the name and IPv6 address of the
server to `yeti-root-servers.txt`.

To delete a Yeti root server you delete the line containing the name
and IPv6 address from `yeti-root-servers.txt`.

To renumber a Yeti root server you change the IPv6 address in the
`yeti-root-servers.txt` file.

To rename a Yeti root server you change the name in the
`yeti-root-servers.txt` file.

We rely on the time information in the ZSK and KSK files to revoke and
remove old keys, so no delete operation is provided.

Generate a Yeti root zone
-------------------------
To generate a root zone the server does this:

1. Download the root zone (F.ROOT-SERVERS.NET is good for this).
2. Check the root zone is correct using DNSSEC validation.
3. If the root serial number is >= `iana-start-serial.txt` then copy
   the `yeti-root-servers.txt` and use that.
4. Modify the root zone:
   a. Remove DNSSEC (NSEC, RRSIG, DNSKEY) records.
   b. Remove records for . (SOA, NS).
   c. Add Yeti SOA.
   d. Add Yeti NS RRSET (based on `yeti-root-servers.txt`).
5. If the root serial number is >= `iana-start-serial.txt` then copy
   any the KSK and ZSK and add them to the existing set used.
6. Sign the root zone (will automatically add needed DNSKEY records).
7. Reload the root zone. (This will send notifies.)


Future Work: ACL
================
An additional configuration that should be synchronized between the
Yeti DM is the ACL of which root servers are allowed to transfer the
Yeti root zone. This can be done in a similar fashion to the
`yeti-root-servers.txt` file. It is possible to synchronize this
without checking the serial number, since it does not affect the
contents of the Yeti root zone.


Future Work: Consistency Protocol
=================================
Communication failures between the Yeti DM can result in inconsistent
Yeti root zone. Solving this requires something like a 2-phase commit
or some other consistency protocol. This coordination protocol has not
been developed, and will be implemented as a future experiment. For
now, we rely on each Yeti DM operator monitoring their systems
carefully, along with uman oversight of the entire process.
