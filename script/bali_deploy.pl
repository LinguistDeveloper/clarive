=head1 NAME

bali_deploy.pl - Baseliner DB Schema Deploy

=head1 DESCRIPTION

Deploy the Baseliner's schema in a database.

Usage, from the command line:

    $ BALI_ENV=<suffix> bali deploy

=head1 OPTIONS

=head2 Run limited test cases

    bali deploy --case job [ --case ... ]

=head2 Run only feature tests

    bali deploy --feature ca.harvest [ --feature ... ]

=cut

use v5.10;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$FindBin::Bin/../lib";
use File::Basename;
use Baseliner::Utils;

our $VERSION = '1.0';

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval nanosleep stat );

BEGIN {
    $ENV{ DBIC_TRACE }                   = 0;
    $ENV{ CATALYST_CONFIG_LOCAL_SUFFIX } = 't';
}

chdir $ENV{BASELINER_HOME} if $ENV{BASELINER_HOME};

my $t0 = [gettimeofday];

sub now {
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
      localtime(time);
    $year += 1900;
    $mon  += 1;
    sprintf "%04d/%02d/%02d %02d:%02d:%02d", ${year}, ${mon}, ${mday}, ${hour},
      ${min}, ${sec};
}

sub pre {
    my $ret = "==============| " . now() . " " . sprintf( "[%.04f]", tv_interval( $t0 ) ). ' ';
    $t0 = [gettimeofday]; 
    $ret;
}

say "Baseliner DB Schema Deploy v$VERSION";

my %args = _get_options( @ARGV );
if( exists $args{h} ) {  # help
    print << 'EOF';
Usage:
  bali deploy [options]

Options:
  -h                      : this help
  -deploy                 : actually execute statements in the db
                              bali deploy --deploy
  -run                    : Run DB statements interactively or from STDIN
  -quote                  : quote table names
  -drop                   : add drop statements
  -env                    : sets BALI_ENV (local, test, prod, t, etc...)
  -schema                 : schemas to deploy (does not work for migrations)
                                bali deploy --schema BaliRepo --schema BaliRepoKeys 

Versioning Options:
  --diff                  : diffs this schema against the database and generates a diff
  --installversion        : installs versioning tables if needed
  --upgrade               : upgrades database version
  --from <version>        : from version (replaces current db version)
  --to <version>          : to version (replaces current schema version)

Examples:
    bin/bali deploy --env t   
    bin/bali deploy --env t --diff
    bin/bali deploy --env t --diff --deploy
    bin/bali deploy --env t --installversion   
    bin/bali deploy --env t --upgrade                   # print migration scripts only, no changes made
    bin/bali deploy --env t --upgrade --deploy          # print migration scripts only, no changes made
    bin/bali deploy --env t --upgrade --show --to 2     # same, but with schema version 2
    bin/bali deploy --env t --upgrade --show --from 1   # same, but with db version 2

EOF
    exit 0;
}

require Carp::Always if exists $args{carp};
$ENV{BASELINER_DEBUG}=1 if exists $args{debug};

# deploy schema
say pre . "Deploying schema " . join', ', _array($args{schema});
say pre . "Starting DB deploy...";
$Baseliner::Schema::Baseliner::DB_DRIVER = 'SQLite';
my $env = $args{env} || $ENV{BALI_ENV} || 't';
$env = @$env if ref $env eq 'ARRAY';
my $cfg_file = "$Bin/../baseliner_$env.conf";
say pre . "Config file: $cfg_file";

require Baseliner::Schema::Baseliner;
require Config::General;
my $cfg      = Config::General->new( $cfg_file );

if( $args{schema} ) {
    $args{schema} = [ _array $args{schema} ];
}

my $dropping= exists $args{drop} ? ' (with DROP)' : '';
if( exists $args{drop} && ! @{ $args{schema} || [] } && ! exists $args{installversion} ) {
    say "\n*** Warning: Drop specified and no --schema parameter found.";
    say "*** All tables in the schema will be dropped. Data loss will ensue.";
    print "*** Are you sure [y/N]: ";
    unless( (my $yn = <STDIN>) =~ /^y/i ) {
        say "Aborted.";
        exit 1;
    }
}
say pre . "Deploying started$dropping.";

my $deploy_now = exists $args{deploy};
say pre . "No deployments will run. Only printing information." unless $deploy_now;

Baseliner::Schema::Baseliner->deploy_schema(
    config          => { $cfg->getall },
    run             => exists $args{run},
    version         => exists $args{'version'},
    install_version => exists $args{'installversion'},
    upgrade         => exists $args{ upgrade },
    diff            => $args{ diff },
    downgrade       => exists $args{ downgrade },
    show_config     => !exists $args{show_config},
    deploy_now      => $deploy_now,
    from            => $args{from}, # from version num
    to              => $args{to},  # to version num
    drop            => exists $args{drop},
    schema          => $args{schema}
) and die pre . "Errors while deploying DB. Aborted\n";

say pre . "No DB statements were executed. Use --deploy to actually deploy/migrate the schema. " unless $deploy_now;
say pre . "Done.";

exit 0;
