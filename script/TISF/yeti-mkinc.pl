#!/usr/bin/env perl

# yeti-mkinc -- create a named.conf "include" file containing yeti config data

use strict;
use warnings;
use YAML::Syck qw/LoadFile/;

our $rootservers_file = '/home/vixie/work/yeticonf/dm/yeti-root-servers.yaml';
our $confinc_file = './named.yeti.inc';

#
# first, load in our configuration data from the YAML, and aggregate it
#

our $rootservers = LoadFile($rootservers_file);

my $also_notify = [];
my $allow_transfer = [];
foreach my $s (@$rootservers) {
	die "missing name" unless defined $s->{name};
	die "missing public_ip" unless defined $s->{public_ip};
	push @$also_notify, ( $s->{notify_addr} || [$s->{public_ip}] );
	push @$allow_transfer, ( $s->{transfer_net} || [$s->{public_ip}] );
}

#
# second, create a named.conf include file (allow-transfer, also-notify)
#

my $confinc = undef;
open($confinc, ">$confinc_file") || die "$confinc_file: $!";
print {$confinc} "allow-transfer {\n";
foreach $_ (@$allow_transfer) {
	print {$confinc} "\t", join(";\n\t\t", @$_), ";\n";
}
print {$confinc} "};\n";
print {$confinc} "also-notify {\n";
foreach $_ (@$also_notify) {
	print {$confinc} "\t", join(";\n\t\t", @$_), ";\n";
}
print {$confinc} "};\n";
close($confinc) || die "$confinc_file: $!";

exit 0;
