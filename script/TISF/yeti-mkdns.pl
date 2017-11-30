#!/usr/bin/env perl

# yeti-mkdns -- creates a yeti zone file based on an IANA file + some metadata
#
# STDERR is diagnostics
# STDOUT is the set of keys to sign with
# $yetiroot_file is the output zone file

use strict;
use warnings;
use Net::DNS::ZoneFile;
use YAML::Syck;
use File::Find;
use POSIX qw/strftime/;

sub wanted_shared;
sub wanted_local;
sub key_dates($);
sub do_zf($$);
sub do_rr($$);
sub output($);
sub load_serial($);

our $yeticonf_dm = '/home/vixie/work/yeticonf/dm';
our $rootservers_file = "./yeti-root-servers.yaml";
our $ianaroot_file = './iana-root.dns';
our $yetiroot_file = './yeti-root.dns';
our $yeti_mname = 'www.yeti-dns.org.';
our $yeti_rname = 'tisf.yeti-dns.org.';
our $local_zskdir = '/home/vixie/work/yeti-tisf/zsk';
our $debug = 0;

#
# first, load in the yeti root name server information and min. serial#
#

our $rootservers = YAML::Syck::LoadFile($rootservers_file);
my $glue = [];
foreach my $s (@$rootservers) {
	die "missing name" unless defined $s->{name};
	die "missing public_ip" unless defined $s->{public_ip};
	next if defined($s->{active}) && $s->{active} ne 'yes';
	push @$glue, join($;, $s->{name}, $s->{public_ip});
}
undef $rootservers;

#
# second, generate the yeti zone from the iana zone
#

our $nameservers = {};
our $addresses = {};
our $addr_ttl = {};
our $yetiroot = undef;
open($yetiroot, ">$yetiroot_file") || die "$yetiroot_file: $!";
# process the IANA root zone
our ($soa_ttl, $soa_serial) = do_zf($ianaroot_file, 0);
# process the DNSKEY files for yeti's keys
our @sharedkeys = ();
our @localkeys = ();
our $mzsk_mode = 0;
find(\&wanted_shared, "$yeticonf_dm/ksk");
find(\&wanted_local, $local_zskdir);
$mzsk_mode = ($#localkeys >= $[);
find(\&wanted_shared, "$yeticonf_dm/zsk");
print join(' ', @sharedkeys, @localkeys), "\n";
# synthesize NS and AAAA RR's from the YAML data
foreach my $ns (@$glue) {
	my ($nsdname, $address) = split /$;/, $ns;
	do_rr(new Net::DNS::RR(name => '.',
			       type => 'NS', nsdname => $nsdname), 0);
	do_rr(new Net::DNS::RR(name => $nsdname,
			       type => 'AAAA', address => $address), 0);
}
# output all referenced A or AAAA RR's, in DNS sort order by hostname
foreach my $ns (sort by_dns keys %$nameservers) {
	my $ref = $addresses->{$ns};
	foreach my $a (sort keys %$ref) {
		output(new Net::DNS::RR(
			name => $ns, type => $addresses->{$ns}->{$a},
			ttl => $addr_ttl->{$ns}->{$addresses->{$ns}->{$a}},
			address => $a
		));
	}
}
close($yetiroot) || die "$yetiroot_file: $!";

exit 0;

#
# wanted_shared -- callback from the ksk/zsk "find"
#
sub wanted_shared {
	# we are looking for any directory containing iana-start-serial.txt
	return unless $_ eq 'iana-start-serial.txt';
	# the contents of that file have to be correct for current serial#
	my $serial = &load_serial($_);
	printf STDERR
		"wanted_shared(%s) serial %u\n", $File::Find::dir, $serial
		if $debug;
	return unless $soa_serial >= $serial;
	# within such directories, *.key files are of potential interest
	my $now = strftime '%Y%m%d%H%M%S', gmtime;
	foreach my $keyfile (<$File::Find::dir/*.key>) {
		my $attr = &key_dates($keyfile);
		next unless defined $attr;
		printf STDERR
			"wanted_shared(%s)\n", $keyfile
			if $debug;
		# if its publication range includes now, publish it
		if ($now ge $attr->{Publish} && $now lt $attr->{Delete}) {
			printf STDERR
				"wanted_shared(%s) do_zf()\n", $keyfile
				if $debug;
			&do_zf($keyfile, 1);
		}
		# if its activity range includes now, and we are not in mzsk
		# mode, then consider it for signing
		if ($now ge $attr->{Activate} && $now lt $attr->{Inactive} &&
		    !$mzsk_mode)
		{
			$_ = $keyfile;
			s:\.key$:.private:o;
			push @sharedkeys, $_ if -e;
			printf STDERR
				"wanted_shared(%s) push %s\n", $keyfile, $_
				if $debug;
		}
	}
}

#
# wanted_local -- callback from the local key "find"
#
sub wanted_local {
	# we are looking for any directory containing iana-start-serial.txt
	return unless $_ eq 'iana-start-serial.txt';
	# within such directories, *.key files are of potential interest
	my $now = strftime '%Y%m%d%H%M%S', gmtime;
	foreach my $keyfile (<$File::Find::dir/*.key>) {
		my $attr = &key_dates($keyfile);
		next unless defined $attr;
#		# if its publication range includes now, publish it
#		if ($now ge $attr->{Publish} && $now lt $attr->{Delete}) {
#			&do_zf($keyfile, 1);
#		}
		# if its activity range includes now, use it for signing
		if ($now ge $attr->{Activate} && $now lt $attr->{Inactive}) {
			$_ = $keyfile;
			s:\.key$:.private:o;
			push @localkeys, $_ if -e;
		}
	}
}

#
# key_dates -- does this pubkey file have good date-metadata for "now"?
#
sub key_dates($) {
	my ($keyfile) = @_;

	my $file = undef;
	open($file, "<$keyfile") || die "$keyfile: $!";
	# ; Created: 20151111203103 (Thu Nov 12 04:31:03 2015)
	# ; Publish: 20151111203103 (Thu Nov 12 04:31:03 2015)
	# ; Activate: 20151115203103 (Mon Nov 16 04:31:03 2015)
	# ; Inactive: 20151129203103 (Mon Nov 30 04:31:03 2015)
	# ; Delete: 20151206203103 (Mon Dec  7 04:31:03 2015)
	my $attr = {};
	while (<$file>) {
		chomp;
		next unless /^\; (\w+)\: (\d{14})/;
		$attr->{$1} = $2;
	}
	return undef unless defined $attr->{Publish};
	return undef unless defined $attr->{Activate};
	return undef unless defined $attr->{Inactive};
	return undef unless defined $attr->{Delete};
	return $attr;
}

#
# do_zf -- load a zone file, overriding the SOA parameters, skipping ./NS RRs
#
sub do_zf($$) {
	my ($zf_file, $allow_dnssec) = @_;
	my ($soa_ttl, $soa_serial);

	my $zf = new Net::DNS::ZoneFile($zf_file, ['.']);
	my $soa_seen = 0;
	while (my $rr = $zf->read) {
		next if $rr->name eq '.' && $rr->type eq 'NS';
		if ($rr->type eq 'SOA') {
			next if $soa_seen;
			$soa_seen = 1;
			$rr->mname($yeti_mname);
			$rr->rname($yeti_rname);
			$soa_ttl = $rr->ttl;
			$soa_serial = $rr->serial;
		}
		do_rr($rr, $allow_dnssec);
	}
	undef $zf;
	return ($soa_ttl, $soa_serial);
}

#
# by_dns -- sort callback that orders $a and $b according to DNS right-to-left
#
sub by_dns {
	my @a = split(/\./, $a);
	my @b = split(/\./, $b);
	for (;;) {
		my $next_a = pop(@a);
		my $next_b = pop(@b);
		if (!defined($next_a) && !defined($next_b)) {
			return 0;
		} elsif (!defined($next_a)) {
			return -1;
		} elsif (!defined($next_b)) {
			return 1;
		}
		my $cmp = $next_a cmp $next_b;
		return $cmp if $cmp != 0;
	}
}

#
# do_rr -- handle one input (or synthetic) RR, remembering NS names and addrs
#
sub do_rr($$) {
	my ($rr, $allow_dnssec) = @_;

	if ($rr->type eq 'NS') {
		$nameservers->{$rr->nsdname} = undef;
	} elsif ($rr->type eq 'A' || $rr->type eq 'AAAA') {
		if (!defined $addresses->{$rr->name}) {
			$addresses->{$rr->name} =
				{ $rr->address => $rr->type };
		} else {
			my $ref = $addresses->{$rr->name};
			$ref->{$rr->address} = $rr->type;
		}
		$addr_ttl->{$rr->name} = {}
			unless defined $addr_ttl->{$rr->name};
		$addr_ttl->{$rr->name}->{$rr->type} = $rr->ttl
			unless defined($addr_ttl->{$rr->name}->{$rr->type}) &&
			       $rr->ttl > $addr_ttl->{$rr->name}->{$rr->type};
		return;
	}
	if (!$allow_dnssec) {
		return if $rr->type eq 'RRSIG';
		return if $rr->type eq 'DNSKEY' && !$rr->zone;
		return if $rr->type eq 'NSEC';
		return if $rr->type eq 'NSEC3';
	}
	output($rr);
}

#
# output -- write one RR, in presentation mode, with a fixed up TTL (from SOA)
#
sub output($) {
	my ($rr) = @_;

	if ($rr->ttl == 0 && $soa_ttl != 0) {
		$rr->ttl($soa_ttl);
	}
	print {$yetiroot} $rr->plain, "\n";
}

#
# load_serial
#
sub load_serial($) {
	my ($filename) = @_;

	my $serial = undef;
	my $f = undef;
	open($f, "<$filename") || die "$filename: $!";
	while (<$f>) {
		chomp;
		die "bad format $filename" unless !defined $serial;
		$serial = 0 + $_;
		die "bad number '$_'" unless $serial > 0;
	}
	undef $f;
	die "empty file $filename" unless defined $serial;
	return $serial;
}
