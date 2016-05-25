#!/usr/bin/perl -I lib

# tests should be run from
# t/12-sysconfig.t
use LedgerSMB::Sysconfig;
use Cwd ;
use List::MoreUtils qw/uniq/;
use strict;
use warnings;

# A list of section.key available from Sysconfig
my @available = LedgerSMB::Sysconfig::available_keys();

# A list of LegacyKeys used in the source
my $repodir = `git rev-parse --show-toplevel`;
chomp($repodir);
# for now we use grep here, perhaps we should in the future refactor and use native perl.
#my $usedkeys_raw = `egrep -i -r --include=*.[pP][lmLM] --exclude-dir=*/doc/ --exclude-dir=*/t/ --exclude-dir=blib --exclude=validate-used-config-keys.pl --exclude=test.pl 'LedgerSMB::Sysconfig::[0-9a-zA-Z_-]*' "$repodir"/**`;
#$usedkeys_raw =~ s|(.*/)([^/]*)(:.*LedgerSMB::Sysconfig::)([0-9a-zA-Z_-]*)(.*)|$4|g;
my $usedkeys_raw = `egrep -i -hr --include=*.[pP][lmLM] --exclude-dir=*/doc/ --exclude-dir=*/t/ --exclude-dir=blib --exclude=validate-used-config-keys.pl --exclude=test.pl 'LedgerSMB::Sysconfig::' "$repodir"/**`;
$usedkeys_raw =~ s|(.*LedgerSMB::Sysconfig::)([0-9a-zA-Z_-]*)(.*)|$2|g;
my %usedkeys = map { $_ => 1 } split(/\n/, $usedkeys_raw);
my @usedkeys = sort keys %usedkeys;

# The list of Keys missing from Sysconfig.pm
my $missingkeys = '';
foreach my $key ( sort { "\L$a" cmp "\L$b" } @usedkeys ) {
    my $pattern = quotemeta( $key );
    if ( ! grep( /\b[.]$pattern\b/, @available) ) {
        $missingkeys .= " - $key\n" ;
    }
}

#The list of Keys not found in the source
my $unusedkeys;
foreach my $key ( sort { "\L$a" cmp "\L$b" } @available ) {
    my $pattern = quotemeta ( $key );
    $pattern =~ s/.*[.]//;
    $unusedkeys .= " - $key\n" if "@usedkeys" !~ m/\b$pattern\b/;
}

# Generate some output
if ( defined $missingkeys) {
    print "These Keys are Used in the src but Missing from Sysconfig.pm\n";
    print "$missingkeys\n";
}

if ( defined $unusedkeys) {
    print "These Keys are in Sysconfig.pm but Missing from the src\n";
    print "$unusedkeys\n";
}

exit


