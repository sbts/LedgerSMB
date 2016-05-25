#!/usr/bin/perl -I lib

# tests should be run from
# t/12-sysconfig.t
use LedgerSMB::Sysconfig;

LedgerSMB::Sysconfig::print_sections ( );
LedgerSMB::Sysconfig::print_section ( 'main');
LedgerSMB::Sysconfig::print_section_brief ( 'main');
LedgerSMB::Sysconfig::print_entry ( 'main','log_level');

#LedgerSMB::Sysconfig::print_all();

print "config file looks like......\n";
LedgerSMB::Sysconfig::print_conffile();

print "\n";
print "Writing config file to disk\n";
LedgerSMB::Sysconfig::write_conffile();

#print "\n\n=====================================================\n";
#print "the value of main.tempdir is : ";
#print LedgerSMB::Sysconfig::value(main, tempdir), "\n";
#print "the value of starman.key2 is : ";
#print LedgerSMB::Sysconfig::value(starman, key2), "\n";
print "=====================================================\n";

print "\n\n";

LedgerSMB::Sysconfig::print_all_brief();


=head
log4perl_config
newscripts
printer
printers
Printers
scripts
=cut