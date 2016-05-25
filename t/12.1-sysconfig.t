#!/usr/bin/perl

use Test::More;

plan skip_all => 'Old Sysconfig.pm structure tests being skipped';

chdir 't/';

require 'LedgerSMB::Sysconfig.pm';


plan tests => (40);

# generate a table of existing defaults using
#   grep --color=always 'our \$' LedgerSMB/Sysconfig.pm | sort

is $LedgerSMB::Sysconfig::auth                  , 'DB'                  , 'default Auth set correctly';
is $LedgerSMB::Sysconfig::backup_email_from     , ''                    , 'default Backup Emailaddress Correct';
like $LedgerSMB::Sysconfig::backuppath          , '/[/]tmp$/'           , 'default Backup Path Correct';
like $LedgerSMB::Sysconfig::cache_template_dir  , '/[/]lsmb_templates$/', 'default Template Cache dir Correct';
is $LedgerSMB::Sysconfig::cache_templates       , 0                     , 'default template caching working';
is $LedgerSMB::Sysconfig::check_max_invoices    , 5                     , 'default max invoices set correctly';
is $LedgerSMB::Sysconfig::cookie_name           , "LedgerSMB-1.3"       , 'default cookie set correctly';
is $LedgerSMB::Sysconfig::cssdir                , 'css/'                , 'default css dir set correctly';
is $LedgerSMB::Sysconfig::db_host               , 'localhost'           , 'default Database Host correct';
is $LedgerSMB::Sysconfig::DBI_TRACE             , 0                     , 'default DBI_TRACE disabled (good)';
is $LedgerSMB::Sysconfig::db_namespace          , 'public'              , 'default DB Namespace correct';
is $LedgerSMB::Sysconfig::db_port               , '5432'                , 'default Database port correct';
is $LedgerSMB::Sysconfig::default_db            , ''                    , 'Default Database Name correct';
is $LedgerSMB::Sysconfig::DefaultDbSuperUser    , 'lsmb_dbadmin'        , 'Default DB SuperUser set correctly';
is $LedgerSMB::Sysconfig::dojo_theme            , 'claro'               , 'default dojo theme correct';
is $LedgerSMB::Sysconfig::force_username_case   , undef                 , 'default force username case disabled (good)'; # don't force case
is $LedgerSMB::Sysconfig::fs_cssdir             , 'css'                 , 'default css fs dir set correctly';
is $LedgerSMB::Sysconfig::gzip                  , "gzip -S .gz"         , 'default gzip command correct';
is $LedgerSMB::Sysconfig::IgnoreDatabaseRegex   , 'postgres|template0|template1', 'default Regex of Databases to Ignore correct';
is $LedgerSMB::Sysconfig::IgnoreDbSuperUserRegex, ''                    , 'default Regex of Database SuperUsers to Ignore correct';
like $LedgerSMB::Sysconfig::images              , '/images$/'           , 'default Image Path is likely correct';
is $LedgerSMB::Sysconfig::language              , "en"                  , 'default language set correctly';
#is $LedgerSMB::Sysconfig::latex, eval {require Template::Plugin::Latex}, 'default Latex availability Ok';
is $LedgerSMB::Sysconfig::localepath            , 'locale/po'           , 'default Locale Path to .po files correct';
#is $LedgerSMB::Sysconfig::log4perl_config      , qq(.........)         , 'default Log 4 Perl config is correct';
is $LedgerSMB::Sysconfig::log_level             , 'ERROR'               , 'default Log level is set to "ERROR" (good)';
is $LedgerSMB::Sysconfig::max_post_size         , 1024 * 1024           , 'default max post size set correctly';
is $LedgerSMB::Sysconfig::memberfile            , "users/members"       , 'default memberfile is correct';
is $LedgerSMB::Sysconfig::no_db_str             , 'database'            , 'default missing-db string set correctly';
is $LedgerSMB::Sysconfig::pathsep               , ':'                   , 'default Path separator set correctly (for linux)';
is $LedgerSMB::Sysconfig::sendmail              , "/usr/sbin/sendmail -t", 'default MTA command is correct';
is $LedgerSMB::Sysconfig::smtpauthmethod        , ''                    , 'default SMTP Auth Method correct';
is $LedgerSMB::Sysconfig::smtphost              , ''                    , 'default SMTP Host correct';
is $LedgerSMB::Sysconfig::smtppass              , ''                    , 'default SMTP password correct';
is $LedgerSMB::Sysconfig::smtptimeout           , 60                    , 'default SMTP Timout correct';
is $LedgerSMB::Sysconfig::smtpuser              , ''                    , 'default SMTP User correct';
is $LedgerSMB::Sysconfig::spool                 , "spool"               , 'default Print Spool dir is correct';
is $LedgerSMB::Sysconfig::sslmode               , 'prefer'              , 'default sslmode is "prefer" (good)';
is $LedgerSMB::Sysconfig::tempdir               , ( $ENV{TEMP} || '/tmp' ), 'default tempdir set correctly';
is $LedgerSMB::Sysconfig::templates             , "templates"           , 'default templates dir correct';
is $LedgerSMB::Sysconfig::userspath             , "users"               , 'default User Path is correct';
is $LedgerSMB::Sysconfig::zip                   , 'zip -r %dir %dir'    , 'default zip command is correct';


#like $ENV{PATH}, '/foo$/', 'appends config path correctly';
