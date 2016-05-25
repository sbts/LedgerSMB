#!/usr/bin/perl

use strict;
use warnings;
#use 5.012;
    use Config;

    use Config::IniFiles;
    my $ConfigFileName='ledgersmb.conf';
    my $cfg = Config::IniFiles->new( -file => $ConfigFileName ) || die @Config::IniFiles::errors;
=head
ehuelsmann (IRC)
m-sbts: def 'pathsep',
    section => 'main',
    key => 'pathsep',
    default => ':',
    doc => qq|
The documentation for the 'main.pathsep' key|;
how about that?
it generates a functional interface LedgerSMB::Sysconfig::pathsep
which can be used as
LedgerSMB::Sysconfig::pathsep('\')
to set the value.
￼ylavoie
ehuelsmann (IRC): Ok, I'll create one for setup for the moment.
E￼ehuelsmann (IRC)
m-ylavoie, we can do that, or pass a variable which says that it should use the 'normal' form?
m-sbts, it sets the default value in the config hash
and it sets the documentation in a doc-hash.
=cut
    # fixme #
    # for now, we read the current version number from LedgerSMB.conf
    # as soon as we branch 1.5,
    # we remove the hard coded number from LedgerSMB and elswhere it's not part of a sanity check
    # and instead hardcode it here in Sysconfig.pm (in the actual declare_config_key() section)
    # and initialize it from Sysconfig or directly use it from Sysconfig as required
    # this $Version variable is only used to initialise the actual main.version key
    my $versionfile = 'LedgerSMB.pm';
    my $Version = '';
    if ( ! -f $versionfile ) { $versionfile = 'lib/LedgerSMB.pm' };     # new dirtree (1.5) location
    if ( ! -f $versionfile ) { $versionfile = '../lib/LedgerSMB.pm' };  # maybe we are running from t/*
    if ( ! -f $versionfile ) { $versionfile = '../../lib/LedgerSMB.pm' }; # maybe we are running from t/data/*
    if ( ! -f $versionfile ) { $versionfile = '../LedgerSMB.pm' };              # old dirtree whe running from t/*
    if ( ! -f $versionfile ) { $versionfile = '../../LedgerSMB.pm' };           # old dirtree when running from t/data/*
    if ( ! -f $versionfile ) { die ("ERROR: can't locate LedgerSMB.pm") };
    open my $version_fh, '<', $versionfile or die "Could not open '$versionfile' $!\n";
    while (my $line = <$version_fh>) {
       chomp $line;
        if ($line =~ /(our\s*\$VERSION\s*=\s*\')(.*)(\'.*)/) {
            $Version=$2;
            last;
        }
    }

#######
# moo class def
#######
package Sysconfig::Entry;
    use strict;
    use warnings;
    use Moo;
    use MooX::Types::MooseLike::Base qw(:all);
    use namespace::autoclean;
    use Config;

    has 'section' => (
        is => 'ro',
        #isa => sub { confess "$_[0] is not a String!" unless is_Str($_[0]) },
        isa => Str,
        required => 1,
    );

    has 'name' => (
        is => 'ro',
        isa => Str,
        required => 1,
    );

    has 'default' => (
        is => 'ro',
        isa => AnyOf[ Str, ArrayRef[] ],
        required => 1,
    );

    has 'value' => (
        is => 'rwp',
        isa => AnyOf[ Str, ArrayRef[] ],
        required => 0,
    );

    has 'summary' => (
        is => 'ro',
        isa => Str,
        required => 1,
    );

    has 'description' => (
        is => 'ro',
        isa => ArrayRef[],
        required => 1,
    );

    has 'configurable' => (
        is => 'ro',
        isa => Bool,
        required => 1,
    );

    has 'writeable' => (
        is => 'ro',
        isa => Bool,
        required => 1,
    );

    has 'deprecated' => (
        is => 'ro',
        isa => Bool,
        required => 0,
    );

    has 'replacedby' => (
        is => 'ro',
        isa => Str,
        required => 0,
    );

    sub BUILDARGS {
        my ( $class, %args ) = @_;
        $args{'value'} = $args{'default'} unless $args{'value'};
        $args{'value'} = $cfg->val($args{'section'},$args{'name'}) if $cfg->val($args{'section'},$args{'name'});
        $args{'value'} = $ENV{"$args{'section'}_$args{'name'}"} if $ENV{"$args{'section'}_$args{'name'}"};

        # if one of the following keys then set an ENV VAR
        if ( "$args{'section'}.$args{'name'}" eq 'environment.PATH' ) {
            $ENV{'PATH'} .= $Config{path_sep} . ( join $Config{path_sep}, $args{'value'});
        } elsif ( "$args{'section'}.$args{'name'}" eq 'environment.PERL5LIB' ) {
            $ENV{'PERL5LIB'} .= $Config{path_sep} . ( join $Config{path_sep}, $args{'value'});
        } elsif ( "$args{'section'}.$args{'name'}" eq 'database.host' ) {
            $ENV{PGHOST} = $args{'value'};
        } elsif ( "$args{'section'}.$args{'name'}" eq 'database.port' ) {
            $ENV{PGPORT} = $args{'value'};
        } elsif ( "$args{'section'}.$args{'name'}" eq 'database.sslmode' ) {
            $ENV{PGSSLMODE} = $args{'value'};
        } elsif ( "$args{'section'}.$args{'name'}" eq 'paths.tempdir' ) {
            $ENV{HOME} = $args{'value'};
        }
        #my $map = { 'database.host' => 'PGHOST', 'database.port' => 'PGPORT', 'paths.tempdir' => 'HOME' };
        #$ENV{$map{$section_name}} = $section_value if exists $map{$section_name};
            #or something like it.
        return \%args;
    };

    ##### not required for Moo #####__PACKAGE__->meta->make_immutable;
no Moo;       # turn off Moo-specific scaffolding

#######
# moo class def
#######
package LedgerSMB::Sysconfig;
    use strict;
    use warnings;
    use Carp qw(confess);
    use Moo;
    use namespace::autoclean;
#    use Data::Dumper;
    binmode STDOUT, ':utf8';
    binmode STDERR, ':utf8';


    use Config; 
    our $pathsep = $Config{path_sep};

    our %EntryStore;
    #has 'EntryStore' => (
    #    #traits => ['Hash'],
    #    is => 'rw',
    #    #isa => 'HashRef[HashRef[Sysconfig::Entry]]',
    #    isa => 'HashRef',
    #);

    sub _ValidSection ($) {
        my($section) = @_;
        my $old_carplevel = $Carp::CarpLevel;
        $Carp::CarpLevel = 1;
        confess("Missing Config Section '$section'")
            unless ( $EntryStore{$section} );
        $Carp::CarpLevel = $old_carplevel;
    }

    sub _ValidEntry ($;$) {
        my($section, $key) = @_;
        my $old_carplevel = $Carp::CarpLevel;
        $Carp::CarpLevel = 1;
        confess("Missing Config Section '$section'")
            unless ( $EntryStore{$section} );
        confess("Missing Config Key '$section.$key'")
            unless ( $EntryStore{$section}{$key} );
        $Carp::CarpLevel = $old_carplevel;
    }

    sub declare_config_key {
    #    my ( $section, $key, $value, $default, $summary, $description, $configurable ) = @_;
        #my $self = shift;
        my(@args) = @_;
        my %tmp = @args;
        $EntryStore{$tmp{section}}{$tmp{name}}=Sysconfig::Entry->new(@args);
    }


#sub def {
#    my ($name, %args) = @_;
#    my $sec = $args{section};
#    my $key = $args{key};
#    $config{$sec}->{$key} = $cfg->val($sec, $key, $args{default});
#    $docs{$sec}->{$key} = $args{doc};
#
#    # create a functional interface
#    *$name = sub {
#        my ($nv) = @_; # new value to be assigned
#        my $cv = $config{$sec}->{$key};
##        $config{$sec}->{$key} = $nv
#            if scalar(@_) > 0;
#        return $cv;
#    };
#}






    sub summary ($;$) {
        #my $self = shift;
        my($section, $key, $value) = @_;
        _ValidEntry($section, $key);
        return $EntryStore{$section}{$key}->summary; # or confess();
    }
    sub description ($;$) {
        #my $self = shift;
        my($section, $key, $value) = @_;
        _ValidEntry($section, $key);
        my $Description = join "\n", @{ $EntryStore{$section}{$key}->description };
        return $Description;
    }
    sub description_as_array ($;$) {
        #my $self = shift;
        my($section, $key, $value) = @_;
        _ValidEntry($section, $key);
        return @ {$EntryStore{$section}{$key}->description };
    }
    sub default ($;$) {
        #my $self = shift;
        my($section, $key, $value) = @_;
        _ValidEntry($section, $key);
        return $EntryStore{$section}{$key}->default;
    }
    sub value ($;$) {
        #my $self = shift;
        my($section, $key, $value) = @_;
        _ValidEntry($section, $key);
        return $EntryStore{$section}{$key}->value;
    }

    sub configurable ($;$) {
        #my $self = shift;
        my($section, $key, $value) = @_;
        _ValidEntry($section, $key);
        return $EntryStore{$section}{$key}->configurable;
    }

    sub writeable ($;$) {
        #my $self = shift;
        my($section, $key, $value) = @_;
        _ValidEntry($section, $key);
        return $EntryStore{$section}{$key}->configurable;
    }

    sub available_keys () {
        my @result;
        foreach my $section ( sort keys %EntryStore ) {
            foreach my $key ( sort keys %{$EntryStore{$section}} ) {
                push (@result, "$section.$key");
            }
        }
        return @result;
    }

    sub print_conffile () {
        print "#===============================================================#\n";
        printf "#== ledgersmb.conf  for version %-25s     ==#\n", $Version;
        print "#===============================================================#\n";
        print "#  This configuration file should normally not be hand edited   #\n";
        print "#  Rather it should be generated and edited using the command   #\n";
        print "#                                                               #\n";
        print "#  lsmb-config \$section \$key \$value                             #\n";
        print "#                                                               #\n";
        print "#  However, you can edit this file to the extent of changing    #\n";
        print "#  a value.                                                     #\n";
        print "#  All other changes will be lost if either of                  #\n";
        print "#    ledgersmb or lsmb-config                                   #\n";
        print "#  write to this file                                           #\n";
        print "#                                                               #\n";
        print "#                                                               #\n";
        print "#                                                               #\n";
        print "#                                                               #\n";
        printf "#  generated %30s                     #\n", ( scalar localtime);
        print "#################################################################\n";
        foreach my $section ( sort keys %EntryStore ) {
            printf "\n[%s]\n", $section;
            foreach my $key ( sort keys %{$EntryStore{$section}} ) {
                if (configurable($section,$key)) {
                    my $comment = ( value($section,$key) eq default($section,$key) ) ? '#' : ' ';
                    printf "  # %s.%s\n", $section, $key;
                    printf "  #  |----- summary: %s\n", summary($section,$key);
                    printf "  #  |- description: %s\n", ( join "\n  #  |               ", description_as_array($section,$key));
                    printf "  #  '----- default: '%s'\n", default($section,$key);
                    printf "  %s          value = '%s'\n", $comment, value($section,$key);
                    #printf "  #  |- configurable: %s\n", configurable($section,$key) ? 'true' : 'false';
                    #printf "  #  '---- writeable: %s\n\n", writeable($section,$key) ? 'true' : 'false';
                    print "\n";
                }
            }
        }
    }

    sub write_conffile () {
        open my $conf_file, '>', $ConfigFileName . ".new" or die "Cannot open file $ConfigFileName.new for writing : $!";
        my $old_fh = select;
        select $conf_file;
        print_conffile;
        select $old_fh;
        close $conf_file;

    }

    sub print_all () {
        print "===========================================================\n";
        print "== All Config Keys                                       ==\n";
        print "===========================================================\n";
        foreach my $section ( sort keys %EntryStore ) {
            foreach my $key ( sort keys %{$EntryStore{$section}} ) {
                printf "  %s.%s\n", $section, $key;
                printf "    |----- summary: %s\n", summary($section,$key);
                printf "    |- description: %s\n", ( join "\n    |               ", description_as_array($section,$key));
                printf "    |----- default: %s\n", default($section,$key);
                printf "    |------- value: %s\n", value($section,$key);
                printf "    |- configurable: %s\n", configurable($section,$key) ? 'true' : 'false';
                printf "    '---- writeable: %s\n\n", writeable($section,$key) ? 'true' : 'false';
            }
        }
    }

    sub print_all_brief () {
        print "===========================================================\n";
        print "== List Config Keys                                      ==\n";
        print "===========================================================\n";
        foreach (available_keys()) {
            print "$_\n";
        }
    }

    sub print_sections () {
        print "===========================================================\n";
        print "==  These Sections are available                         ==\n";
        print "===========================================================\n";
        foreach my $section ( sort keys %EntryStore ) {
            print "  $section\n";
        }
        print "\n";
    }

    sub print_section ($) {
        my($section) = @_;
        _ValidSection($section);
        print "===========================================================\n";
        printf "==  Section %-44s ==\n", "'$section' contains these keys";
        print "===========================================================\n";
        foreach my $key ( sort keys %{$EntryStore{$section}} ) {
            printf "  %s\n", $key;
            printf "    |------ summary: %s\n", summary($section,$key);
            printf "    |-- description: %s\n", ( join "\n    |               ", description_as_array($section,$key));
            printf "    |------ default: %s\n", default($section,$key);
            printf "    |-------- value: %s\n", value($section,$key);
            printf "    |- configurable: %s\n", configurable($section,$key) ? 'true' : 'false';
            printf "    '---- writeable: %s\n\n", writeable($section,$key) ? 'true' : 'false';
        }
    }

    sub print_section_brief ($) {
        my($section) = @_;
        _ValidSection($section);
        print "===========================================================\n";
        printf "==  Section %-44s ==\n", "'$section' contains these key/value pairs";
        print "===========================================================\n";
        foreach my $key ( sort keys %{$EntryStore{$section}} ) {
            my $comment = ( value($section,$key) eq default($section,$key) ) ? '#' : ' ';
            printf "  %s  %s = %s\n", $comment, $key, value($section,$key);
        }
        print "\n";
    }

    sub print_entry ($;$) {
        my($section, $key, $value) = @_;
        _ValidEntry($section, $key);
        print "===========================================================\n";
        printf "==  %-52s ==\n", "$section.$key";
        print "===========================================================\n";
        printf "      summary: %s\n", summary($section,$key);
        printf "  description: %s\n", ( join "\n               ", description_as_array($section,$key)); #description($section,$key);
        printf "      default: %s\n", default($section,$key);
        printf "        value: %s\n", value($section,$key);
        printf " configurable: %s\n", configurable($section,$key) ? 'true' : 'false';
        printf "    writeable: %s\n\n", writeable($section,$key) ? 'true' : 'false';
    }

no Moo;

declare_config_key (
    section      => 'main',
    name         => 'VERSION',
    default      => $Version,
#    value        => 'z',
    summary      => 'Current LedgerSMB Version',
    description  => [ 'Hardcoded non editable version number for the current instance of LedgerSMB' ],
    configurable => 0,
    writeable    => 0,
);

declare_config_key (
    section      => 'main',
    name         => 'auth',
    default      => 'DB',
    summary      => 'Authorisation type',
    description  => [ 'Configures which authentication plugin is to be used.',
                      'DB: lib/LedgerSMB/Auth/DB.pm',
                      'There are currently no other options'
                    ],
    configurable => 0,
    writeable    => 0,
);

declare_config_key (
    section      => 'main',
    name         => 'cache_templates',
    default      => '0',
    summary      => 'cache templates',
    description  => [ 'If set to a true value this caches templates.',
                      'Enabling this will potentially speedup some operations.',
                      '0: disable or 1: enable.',
                    ],
    configurable => 1,
    writeable    => 1,
);


declare_config_key (
    section      => 'main',
    name         => 'language',
    default      => 'en_US',
    summary      => 'Set language for login and admin pages',
    description  => [ 'see locale/po/* for available options.', ],
    configurable => 1,
    writeable    => 1,
);


declare_config_key (
    section      => 'main',
    name         => 'log_level',
    default      => 'ERROR',
    summary      => 'Log4perl log level',
    description  => [ 'see https://metacpan.org/pod/Log::Log4perl#Log-Levels for details on this setting',
                      'FATAL, ERROR, WARN, INFO, DEBUG, and TRACE (in descending priority)',
                    ],
    configurable => 1,
    writeable    => 1,
);


declare_config_key (
    section      => 'main',
    name         => 'DBI_TRACE',
    default      => '0',
    summary      => 'File to write DBI_TRACE output to',
    description  => [ '0: none  1: /tmp/dbi.trace', ],
    configurable => 1,
    writeable    => 1,
);


declare_config_key (
    section      => 'main',
    name         => 'max_post_size',
    default      => '4194304',
    summary      => 'Maximum POST size to prevent DoS (4MB default)',
    description  => [ 'This is an arbitrary limit, feel free to change it as required.', ],
    configurable => 1,
    writeable    => 1,
);


declare_config_key (
    section      => 'main',
    name         => 'cookie_name',
    default      => "LedgerSMB-$Version",
    summary      => 'Cookie name for this instance of LedgerSMB',
    description  => [ 'Used to keep multiple instances and/or versions logged in at the same time.', ],
    configurable => 1,
    writeable    => 1,
);


declare_config_key (
    section      => 'main',
    name         => 'no_db_str',
    default      => 'database',
    summary      => 'failed db connection error detection string',
    description  => [   'This is the string we look for in the failed connection error to determine',
                        'if the database was not found.  For English-language locales, this can be',
                        'left in place.  If the database server is running a different locale, it may',
                        'need to be changed.  Any partial match on the connection error assumes that',
                        'the failure to connect was caused by an invalid database request.',
                    ],
    configurable => 1,
    writeable    => 1,
);


#declare_config_key (
#    section      => 'main',
#    name         => '',
#    default      => '',
#    summary      => '',
#    description  => [  '',
#                    ],
#    configurable => 1,
#    writeable    => 1,
#);



#PERL_LOCAL_LIB_ROOT='/home/dcg/perl5'
#PERL_MM_OPT=INSTALL_BASE=/home/dcg/perl5

declare_config_key (
    section      => 'main',
    name         => 'dojo_theme',
    default      => 'claro',
    summary      => 'Dojo theme to be used by default',
    description  => [  '# This is the Dojo theme to be used by default -- e.g. when no other theme',
                       '# has been selected.',
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'main',
    name         => 'dojo_built',
    default      => '1',
    summary      => 'Use built version of dojo',
    description  => [  '# This is the boolean indicating if dojo\'s compacted output ("built output")',
                       '# should be used or the development version [1 = \'true\' ==> \'built version\']',
                       '',
                    ],
    configurable => 1,
    writeable    => 1,
);


declare_config_key (
    section      => 'environment',
    name         => 'PATH',
    default      => '/usr/local/pgsql/bin:/usr/local/bin:/usr/bin:/bin',
    summary      => 'filesearch path',
    description  => [  '# If the server can\'t find applications, append to the path',
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'paths',
    name         => 'spool',
    default      => 'spool',
    summary      => '# spool directory for batch printing',
    description  => [  '# spool directory for batch printing',
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'paths',
    name         => 'tempdir',
    default      => '/tmp/ledgersmb',
    summary      => 'location for tempfiles',
    description  => [ 'Be aware of tempdir setting.',
                      'If client_browser and server_apache are on the same machine, and share tmp-dir,',
                      'you may get problems like \'Permission denied\' if server tries to write to',
                      'a temp-file which already exists as client-owned.'
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'paths',
    name         => 'css_uri',
    default      => 'css/',
    summary      => 'logical CSS directory',
    description  => [ 'This is the CSS location as used in URL\'s.',
                      'ie: it is what comes before the ledgersmb.css in the url.',
                      'An example might be /my_css_dir/ or http://localhost/other_css_dir/',
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'paths',
    name         => 'css_ondisk',
    default      => 'css/',
    summary      => 'CSS directory',
    description  => [ 'The on disk location for where css files are stored.',
                      'This is primarily used to allow editing and selection of CSS within the UI',
                      'An example might be /var/www/ledgersmb_css/',
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'paths',
    name         => 'user_css_ondisk',
    default      => 'css-local/',
    summary      => 'user customised CSS directory',
    description  => [ 'The on disk location for where user customized css files are stored.',
                      'This allows css overrides to be put in place',
                      'An example might be /var/www/ledgersmb_css/',
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'paths',
    name         => 'userspath',
    default      => 'users',
    summary      => 'path to user configuration files',
    description  => [  'path to user configuration files',
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'paths',
    name         => 'templates',
    default      => 'templates',
    summary      => 'templates base directory',
    description  => [  '',
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'paths',
    name         => 'images',
    default      => 'images',
    summary      => 'images base directory',
    description  => [  'images base directory',
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'paths',
    name         => 'memberfile',
    default      => 'users/members',
    summary      => 'member file',
    description  => [  'member file',
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'paths',
    name         => 'localepath',
    default      => 'locale/po',
    summary      => 'Translation File Directory',
    description  => [  'Directory where .po (translation) files are found',
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'programs',
    name         => 'gzip',
    default      => 'gzip -S .gz',
    summary      => 'gzip program to use for file compression',
    description  => [  'gzip program to use for file compression',
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'programs',
    name         => 'zip',
    default      => 'zip -r %dir %dir',
    summary      => 'zip program to use for file compression',
    description  => [  'zip program to use for file compression',
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'programs',
    name         => 'latex',
    default      => '1',
    summary      => 'Enable LaTeX processing',
    description  => [  '1 = enable LaTeX use',
                       '0 = disable LaTeX use',
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'mail',
    name         => 'sendmail',
    default      => '/usr/bin/sendmail',
    summary      => 'sendmail binary location',
    description  => [  'How to send mail.  The sendmail command is used unless smtphost is set.',
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'mail',
    name         => 'smtphost',
    default      => '127.0.0.1',
    summary      => 'Mail Server URL or address',
    description  => [  'The Mailserver URL or Address to use when sending mail directly',
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'mail',
    name         => 'smtptimeout',
    default      => '60',
    summary      => 'Timeout for Mail Server comms',
    description  => [  'Timeput for Mail Server comms',
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'mail',
    name         => 'backup_email_from',
    default      => 'backups@lsmb_hosting.com',
    summary      => 'Sender Address when sending backup emails',
    description  => [  'Sender Address when sending backup emails',
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'printers',
    name         => 'Laser',
    default      => 'lpr -Plaser',
    summary      => 'Sample Laser Printer Config',
    description  => [  '',
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'printers',
    name         => 'Epson',
    default      => 'lpr -PEpson',
    summary      => 'Sample Epson Printer',
    description  => [  '',
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'database',
    name         => 'port',
    default      => '5432',
    summary      => 'Database Connection Port',
    description  => [  '',
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'database',
    name         => 'default_db',
    default      => 'lsmb${version}',
    summary      => 'Default Company (DB) Name to use at login',
    description  => [  'Note that default_db can be left blank',
                       'if you want to force people to enter a company name at login.',
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'database',
    name         => 'host',
    default      => 'localhost',
    summary      => 'Hostname for DB connection',
    description  => [  '',
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'database',
    name         => 'db_namespace',
    default      => 'public',
    summary      => 'Namespace to use when connecting to the DB',
    description  => [  '',
                    ],
    configurable => 0,
    writeable    => 0,
);

declare_config_key (
    section      => 'database',
    name         => 'sslmode',
    default      => 'prefer',
    summary      => '# sslmode can be require, allow, prefer, or disable.  Defaults to prefer.',
    description  => [  '# sslmode can be require, allow, prefer, or disable.  Defaults to prefer.',
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'log4perl_config_modules_loglevel',
    name         => 'LedgerSMB',
    default      => 'INFO',
    summary      => 'log4perl setting',
    description  => [  '',
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'log4perl_config_modules_loglevel',
    name         => 'LedgerSMB.DBObject',
    default      => 'INFO',
    summary      => 'log4perl setting',
    description  => [  '',
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'paths',
    name         => 'backuppath',
    default      => '/tmp/ledgersmb',
    summary      => 'Path for Database Backup tempfiles',
    description  => [  'location where the temp files for database backups are being sent',
                    ],
    configurable => 0,
    writeable    => 0,
);

declare_config_key (
    section      => 'paths',
    name         => 'cache_template_dir',
    default      => '$tempdir/lsmb_templates',
    summary      => 'cache dir for templates',
    description  => [  '',
                    ],
    configurable => 0,
    writeable    => 0,
);

declare_config_key (
    section      => 'main',
    name         => 'force_username_case',
    default      => 'mixed',
    summary      => 'force username case',
    description  => [  'available values',
                       'mixed',
                       'upper',
                       'lower',
                    ],
    configurable => 0,
    writeable    => 0,
);

declare_config_key (
    section      => 'zmain',
    name         => 'io_lineitem_columns',
    default      => [ qw(unit onhand sellprice discount linetotal) ],
    summary      => 'io_lineitem_columns',
    description  => [  '',
                    ],
    configurable => 1,
    writeable    => 1,
);

declare_config_key (
    section      => 'main',
    name         => 'scripts',
    default      => [ qw(
                        aa.pl am.pl ap.pl ar.pl arap.pl arapprn.pl
                        gl.pl ic.pl ir.pl is.pl oe.pl pe.pl
                    ) ],
    summary      => 'Old Scripts',
    description  => [  '',
                    ],
    configurable => 0,
    writeable    => 0,
);

declare_config_key (
    section      => 'main',
    name         => 'newscripts',
    default      => [ qw(
                        account.pl admin.pl asset.pl budget_reports.pl budgets.pl business_unit.pl
                        configuration.pl contact.pl contact_reports.pl drafts.pl
                        file.pl goods.pl import_csv.pl inventory.pl invoice.pl inv_reports.pl
                        journal.pl login.pl lreports_co.pl menu.pl order.pl payment.pl payroll.pl
                        pnl.pl recon.pl report_aging.pl reports.pl setup.pl taxform.pl template.pl
                        timecard.pl transtemplate.pl trial_balance.pl user.pl vouchers.pl
                    ) ],
    summary      => 'New Scripts',
    description  => [  '',
                    ],
    configurable => 0,
    writeable    => 0,
);

declare_config_key (
    section      => 'main',
    name         => 'return_accno',
    default      => '',
    summary      => 'the account number to book refunds on that are associated with item returns',
    description  => [  'This setting should be relocated to the DB in the near future',
                    ],
    configurable => 1,
    writeable    => 1,
);

# The following Keys are Depricated or have been renamed
declare_config_key (
    section      => 'main',
    name         => 'cssdir',
    default      => 'deprecated',
    summary      => 'please rename to css_uri',
    description  => [ 'deprecated',],
    configurable => 0,
    writeable    => 0,
    deprecated   => 1,
    replacedby   => 'css_uri',
);

declare_config_key (
    section      => 'main',
    name         => 'fs_cssdir',
    default      => 'deprecated',
    summary      => 'please rename to css_ondisk',
    description  => [ 'deprecated',],
    configurable => 1,
    writeable    => 1,
    deprecated   => 1,
    replacedby   => 'css_ondisk',
);

#declare_config_key (
#    section      => 'programs',
#    name         => 'pdflatex',
#    default      => '/usr/bin/pdflatex',
#    summary      => 'path to pdflatex',
#    description  => [  '# For latex and pdflatex, specify  full path.  These will be used to configure',
#                       '# Template::Latex so it can find them.  This can be used to specify programs',
#                       '# other than vanilla latex and pdflatex, such as the xe varieties of either one,',
#                       '# if unicode is required.',
#                       '#',
#                       '# If these are not set, the package defaults (set when you installed.',
#                       '# Template::Latex) will be used',
#                    ],
#    configurable => 0,
#    writeable    => 0,
#    deprecated   => 1,
#);
#
#declare_config_key (
#    section      => 'programs',
#    name         => 'latex',
#    default      => '/usr/bin/latex',
#    summary      => 'path to latex',
#    description  => [  '# For latex and pdflatex, specify  full path.  These will be used to configure',
#                       '# Template::Latex so it can find them.  This can be used to specify programs',
#                       '# other than vanilla latex and pdflatex, such as the xe varieties of either one,',
#                       '# if unicode is required.',
#                       '#',
#                       '# If these are not set, the package defaults (set when you installed.',
#                       '# Template::Latex) will be used',
#                    ],
#    configurable => 0,
#    writeable    => 0,
#    deprecated   => 1,
#    replacedby   => 'latex boolean',
#);
#
#declare_config_key (
#    section      => 'programs',
#    name         => 'dvips',
#    default      => '/usr/bin/dvips',
#    summary      => 'path to dvips',
#    description  => [  '# For latex and pdflatex, specify  full path.  These will be used to configure',
#                       '# Template::Latex so it can find them.  This can be used to specify programs',
#                       '# other than vanilla latex and pdflatex, such as the xe varieties of either one,',
#                       '# if unicode is required.',
#                       '#',
#                       '# If these are not set, the package defaults (set when you installed.',
#                       '# Template::Latex) will be used',
#                    ],
#    configurable => 0,
#    writeable    => 0,
#    deprecated   => 1,
#);


