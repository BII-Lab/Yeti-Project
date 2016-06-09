WARNING
=======
This describes the Yeti DM synchronization protocol as used by the
Multi-ZSK experiment, which ended in 2016-04. Look at Yeti-DM-Sync.md
for the current production documentation.

Introduction
============
This is a modification of the synchronization protocol that will allow
each of the Yeti Distribution Master (DM) to generate new ZSK
independently of each other. It is part of the Multiple-ZSK
experiment, but is intended to remain in production when that
experiment is complete (assuming that it is successful and
Multiple-ZSK operation works well).

A set of changes from the non-Multiple-ZSK version is listed at the
end of this document.


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

* `yeti-root-servers.yaml`
* `iana-start-serial.txt`

Additionally, it has the following directory structure:

* `ksk/`
  * `ksk-2015112601/`
    * `iana-start-serial.txt`
    * `K.+008+03558.key`
    * `K.+008+03558.private`
  * `ksk-2015112801/`
    * ...
* `zsk/`
  * `bii/`
    * `zsk-2015112500/`
      * `iana-start-serial.txt`
      * `K.+008+59676.key`
    * `zsk-2015112903/`
      * ...
  * `tisf/`
    * `zsk-2016020100/`
      * ...
  * `wide/`
    * ...

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
  addresses. If it is not present, then the `public_ip` of the server
  is used instead.
* `notify_addr` is optional, and is a list of IPv6 addresses. If it is
  not present, then the `public_ip` of the server is used instead.

The `iana-start-serial.txt` file contains the serial in the SOA of the
IANA root zone when to start using the data:

    2015092300

## KSK subdirectories

The KSK directory contains a number of subdirectories, created with a
unique name based on the ISO 8601 date format, with a number at the
end to allow for more than one per day if necessary (up to 100). Each
directory contains any number of `.key` files which is in the format
that BIND 9 `dnssec-keygen` creates.  It also contains a `.private`
file for each `.key` file, with the secret information.

The KSK directories each contain a file called
`iana-start-serial.txt`, which contains the serial in the SOA of the
IANA root zone when to start using the contents of the directory.

## ZSK subdirectories

The ZSK directory contains three subdirectories, named for each of the
DM operators: bii, tisf, and wide.

Each DM operator subdirectory contains a number of subdirectories,
created with a unique name based on the ISO 8601 date format, with a
number at the end to allow for more than one per day if necessary (up
to 100).

Each directory contains any number of `.key` files which is in the
format that BIND 9 `dnssec-keygen` creates.

The ZSK directories each contain a file called
`iana-start-serial.txt`, which contains the serial in the SOA of
the IANA root zone when to start using the contents of the directory.

Operations
==========
There are a number of operations that the distributors need to
perform.

Change Data
-----------
The various operations that change data are:

* Add/delete/renumber/rename Yeti root server
* Change to a new set of KSK
* Change to a new set of ZSK

The logic add/delete/renumber/rename of Yeti root servers is:

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

To change the KSK and ZSK, the logic is:

1. Make a directory named "{ksk,zsk}-YYYYMMDD##", where YYYYMMDD is the
   current date and ## is a number, starting with 00.
2. Put all of the desired KSK or ZSK files into the new directory.
3. Create `iana-start-serial.txt`
   as appropriate, with a serial 2 days in the future.
4. "git add"/"git commit"/"git push" of the directory.

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
5. Find the latest KSK directory where the serial number is <= the
   root serial number. Find all the ZSK directories where the serial
   number is <= the root serial number. 
6. Add the KSK and ZSK found there into DNSKEY when "Publish<time<Delete"
7. Use the keys found there signing the root zone when "Active<time<Inactive"
   Note that the signing process should use the active ZSK private key that 
   the DM doing the signing is using, as well as the KSK private key from the 
   repository.
8. Reload the root zone. (This will send notifies.)

Future Work: Consistency Protocol
=================================
Communication failures between the Yeti DM can result in inconsistent
Yeti root zone. Solving this requires something like a 2-phase commit
or some other consistency protocol. This coordination protocol has not
been developed, and will be implemented as a future experiment. For
now, we rely on each Yeti DM operator monitoring their systems
carefully, along with human oversight of the entire process.


Future Work: Pre-share Multiple Keys
====================================
Using the directory structure, it is possible to pre-share any
number of keys (or indeed all keys for the lifetime of the project).


Future Work: Figure out the KSK signing process
===============================================
Right now we assume that each DM operator has access to the KSK secret
material. Ultimately this should change, so that there is a true
separation of authority between the KSK and ZSK holders.


Changes from non-Multi-ZSK Synchronization
==========================================
This method is meant to be similar to the existing method.

The following changes were necessary:

* All refereneces to private key information were removed. KSK private
  key information must be handled out of band, and ZSK private key
  information is no longer shared at all.

* The ZSK directory now has separate subdirectories for each DM. While
  not strictly necessary this will help identify the DM responsible
  for each ZSK.

* Removed "Future Work" for multiple ZSK and hiding all secrets, as
  these are done in this experiment.
