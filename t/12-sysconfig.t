#!/usr/bin/perl -I lib

use Test::More;

chdir 't/data';

require '../../lib/LedgerSMB/Sysconfig.pm';


plan tests => (11+scalar(@LedgerSMB::Sysconfig::scripts)
               +scalar(@LedgerSMB::Sysconfig::newscripts));

is LedgerSMB::Sysconfig::value(main, auth),                 'DB2',      'Auth set correctly';
is LedgerSMB::Sysconfig::value(paths, tempdir),             'test',     'tempdir set correctly';
is LedgerSMB::Sysconfig::value(paths, css_uri),              'css3/',    'css dir set correctly';
is LedgerSMB::Sysconfig::value(paths, css_ondisk),           'css4',     'css fs dir set correctly';
is LedgerSMB::Sysconfig::value(main, cache_templates),      5,          'template caching working';
is LedgerSMB::Sysconfig::value(main, language),             'en2',      'language set correctly';
#is $LedgerSMB::Sysconfig::value(main, check_max_invoices),   '52',       'max invoices set correctly';
is LedgerSMB::Sysconfig::value(main, max_post_size),        4194304333, 'max post size set correctly';
is LedgerSMB::Sysconfig::value(main, cookie_name),          'LedgerSMB-1.32', 'cookie set correctly';
is LedgerSMB::Sysconfig::value(main, no_db_str),            'database2', 'missing db string set correctly';

like $ENV{PATH}, '/foo$/', 'appends config path correctly';

for my $script (LedgerSMB::Sysconfig::value(main, scripts)) {
    ok(-f '../../bin/' . $script, "Whitelisted oldcode script $script exists");
}

for my $script (LedgerSMB::Sysconfig::value(main, newscripts)) {
    $script =~ s/\.pl$/.pm/;
    ok(-f '../../lib/LedgerSMB/Scripts/' . $script,
       "Whitelisted script $script exists");
}
