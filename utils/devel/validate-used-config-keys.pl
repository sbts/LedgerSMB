#!/usr/bin/perl -I lib

# tests should be run from
# t/12-sysconfig.t
use LedgerSMB::Sysconfig;
use Cwd ;
use List::MoreUtils qw/uniq/;
use strict;
use warnings;

my $ignore_regex = qr/EntryStore|environment\.PATH|database\.host|database\.port|database\.sslmode|log4perl_.*|printers\./;
my $old_sysconfig = 0;

# We assume we are inside a git repository when running this.
# but the current working dir could be at any level of the tree so findout what the top level is.
my $repodir = `git rev-parse --show-toplevel`;
chomp($repodir); # get rid of the trailing newline that the backtick call returns
if ( ! -d $repodir ) { $repodir = getcwd; } # if we aren't in a git repo or something went wrong, assume we are running from the top level dir and continue
if ( ! -r "$repodir/lib/LedgerSMB.pm" ) { $repodir = Cwd::abs_path( "$repodir/../../" ); } # we probably aren't in a repo and are running from utils/devel or t/data*
if ( ! -r "$repodir/lib/LedgerSMB.pm" ) { 
    print "\n\nERROR: we don't seem to be able to find the top level of the src tree.\n\n";
    exit;
}

# $match_pattern is used to filter the files with system grep
# $file is a shell file glob relative to $repodir.  it would normally be a specific path/name or '**' for all files
# $substitution_pattern should have at least 1 sub expressions, only $1 (the result of the first sub expression is returned, everything else is deleted.
sub code_grep( $ $ $ $ ) {
    my ( $match_pattern, $file, $substitution_pattern, $ignore_regex ) = @_;
    if ( ! defined $ignore_regex ) { $ignore_regex = 'No Ignores'; } # default to a regex that would never be a valid keyname
    # #### example code to Get all of the files in the current dir and all the subdirs and do something with them
    #use File::Find;
    ## Run this program and give it the arg elementTake57a_inertia
    #$finalBasename = $ARGV[0];
    #&File::Find::find(
    #    sub {
    #        my($basename, $frame, $ext) = $_ =~
    #            /([^\/]*)   # basename - non-slash chars
    #            \.          # literal dot
    #            (\d+)               # frame number - digits
    #            \.(\w+)$/x; # extention - ends w/ letters+numbers
    #        my $dir = $File::Find::dir;
    #        if ($basename eq $finalBasename) {
    #            rename($File::Find::name,
    #                ($dir . '/final.' . $frame . '.' . $ext));
    #        }
    #    }, "."
    #);
    # for now we use grep here, perhaps we should in the future refactor and use native perl.
    my $keys = `egrep -i -hr --include=*.[pP][lmLM] --exclude-dir=*/doc/ --exclude-dir=*/t/ --exclude-dir=blib --exclude=validate-used-config-keys.pl --exclude=test.pl --exclude=test-sysconfig.pl $match_pattern "$repodir/"$file`;
    $keys =~ s|$substitution_pattern|$1|g;              # strip everything except the portion matching the first subexpression
    $keys =~ s/$ignore_regex//g;                        # strip all keys these keys from the result as we want to ignore them for various reasons
    my %keys = map { $_ => 1 } split(/\n/, $keys);      # create a hash from the result disposing of duplicates
    my @result = sort { "\L$a" cmp "\L$b" } keys %keys; # sort the keys case insensitively
    return @result;
}

# A list of section.key available from Sysconfig
    my @available = '';
    if ( defined &LedgerSMB::Sysconfig::available_keys ) {
        @available = LedgerSMB::Sysconfig::available_keys();
        # remove any keys that match $ignore_regex
        my @del_indexes = reverse(grep { $available[$_] =~ $ignore_regex } 0..$#available);
        foreach my $item (@del_indexes) {
            splice (@available,$item,1);
        }
    } else {
        print "Old Sysconfig.pm being used\n";
        $old_sysconfig = 1;
    }

# find all "our [$@%]key" declarations and return an array the key names
# this is to cover legacy keys still declared in Sysconfig.pm
    my @available_legacy = code_grep( '^[[:space:]]*[^#]*our[[:space:]][\$%@]', "lib/LedgerSMB/Sysconfig.pm", '.*our[[:space:]][\$@%]([0-9a-zA-Z_-]*).*', $ignore_regex );

    my @allavailable = @available;
    push(@allavailable, @available_legacy);

# find all the LegacyKeys used in the source and return an array
    my @usedkeys_legacy = code_grep( 'LedgerSMB::Sysconfig::', '**', '.*LedgerSMB::Sysconfig::([0-9a-zA-Z_-]*).*', '' );

# The list of Keys missing from Sysconfig.pm
my $missingkeys = '';
foreach my $key ( @usedkeys_legacy ) {
    my $pattern = quotemeta( $key ); # quote meta chars so any unexpected chars don't crash the code, instead we simply won't match anything
    if ( ! grep( /\b$pattern$/, @allavailable) ) { # match against the end of each key so we ignore the section which isn't available in usedkeys_legacy
        $missingkeys .= " - $key\n";
    }
}

#The list of Keys not found in the source
my $unusedkeys;
foreach my $key ( sort { "\L$a" cmp "\L$b" } @allavailable ) {
    my $pattern = quotemeta ( $key );
    $pattern =~ s/.*[.]//;
    $unusedkeys .= " - $key\n" if "@usedkeys_legacy" !~ m/\b$pattern\b/;
}

# Generate some output
    if ( $old_sysconfig == 0 ) {
        # start by listing the legacy keys still provided by Sysconfig.pm
        print "=========  legacy keys still in use  ==========\n";
        foreach my $key (@available_legacy) {
            print " - $key\n" if $key !~ m/EntryStore/;
        }
        print "===============================================\n\n";
    }
    # now report any keys that are used but missing from Sysconfig.pm
    if ( defined $missingkeys) {
        print "These Keys are Used in the src but Missing from Sysconfig.pm\n";
        print "$missingkeys\n";
    }

    # now report any keys that are provided by Sysconfig.pm but not used by or missing from the src
    if ( defined $unusedkeys) {
        print "These Keys are in Sysconfig.pm but Missing from the src\n";
        print "$unusedkeys\n";
    }

exit


