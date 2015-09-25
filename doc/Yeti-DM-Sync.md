Background
==========
Each Yeti Distribution Master (DM) needs to publish the same root zone
file as the other DM. In order to do this, the DM need to synchronize
the information used to produce and publish the root zone. This
includes:

* the list of Yeti root servers, including:
    * public IPv6 address
    * host name
    * IPv6 addresses originating zone transfer
    * IPv6 addresses to send DNS notify to
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

Any firewall must allow access from the IPv6 prefixes designated by
the coordinators.

Only the master branch is used.


Details of Files
================
The Git repository has the following files:

* yeti-root-servers.yaml
* iana-start-serial.txt
* yeti-root-ksk.key
* yeti-root-ksk.private
* yeti-root-zsk.key
* yeti-root-zsk.private

The `yeti-root-servers.yaml` file contains one entry per Yeti root
server, which has the server name, public IPv6 address, IPv6 networks
to allow transfer from, and IPv6 addresses to send NOTIFY packets to.
An example:

```yaml
    # BII
    - name:          bii.dns-lab.net
      public_ip:     240c:f:1:22::6
      transfer_net:  [ "240c:f:1:23::/48", "240c:f:1:24::6" ]
      notify_addr:   [ "240c:f:1:23::6", "240c:f:1:24::6" ]

    # TISF
    - name:          yeti-ns.tisf.net
      public_ip:     2001:559:8000::6
```

Each Yeti root starts with a '-' and then contains information about
it. The following rules apply to each type of variable:

    * `name` is required, and is a host name
    * `public_ip` is required, and is an IPv6 address
    * `transfer_net` is optional, and is a list of IPv6 prefixes or
      addresses. If it is not present, then the `public_ip` of the
      server is used instead.
    * `notify_addr` is optional, and is a list of IPv6 addresses. If
      it is not present, then the `public_ip` of the server is used
      instead.

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

1. Check to make sure that no operation is pending (if the
   `iana-start-serial.txt` is in the future, an operation is pending).
2. Update the appropriate file in the directory.
3. Update the `iana-start-serial.txt` file with a serial 2 days in the
   future.
3. "git add"/"git commit"/"git push" of the file(s) and the
   `iana-start-serial.txt` file.

All of the basic CRUD (Create, Read, Update, Delete) operations on the
list of Yeti root servers is made by changing the
`yeti-root-servers.yaml` file.

We rely on the time information in the ZSK and KSK files to revoke and
remove old keys, so no delete operation is provided.

Generate a Yeti root zone
-------------------------
To generate a root zone the server does this:

1. Download the root zone (F.ROOT-SERVERS.NET is good for this).
2. Check the root zone is correct using DNSSEC validation.
3. If the root serial number is >= `iana-start-serial.txt` then copy
   the `yeti-root-servers.yaml` and use that.
4. Modify the root zone:
    1. Remove DNSSEC (NSEC, RRSIG, DNSKEY) records.
    2. Remove records for . (SOA, NS).
    3. Add Yeti SOA.
    4. Add Yeti NS RRSET (based on `yeti-root-servers.yaml`).
5. If the root serial number is >= `iana-start-serial.txt` then copy
   any the KSK and ZSK and add them to the existing set used.
6. Sign the root zone (will automatically add needed DNSKEY records).
7. Reload the root zone. (This will send notifies.)


Future Work: Consistency Protocol
=================================
Communication failures between the Yeti DM can result in inconsistent
Yeti root zone. Solving this requires something like a 2-phase commit
or some other consistency protocol. This coordination protocol has not
been developed, and will be implemented as a future experiment. For
now, we rely on each Yeti DM operator monitoring their systems
carefully, along with human oversight of the entire process.


Future Work: Pre-publish Multiple Keys
======================================
Rather than synchronize keys using this protocol, we could instead
share a set of keys for the future between the coordinators. This
would make synchronization by a protocol unnecessary.
