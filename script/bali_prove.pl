=head1 NAME

bali_prove.pl - Baseliner Test Harness

=head1 DESCRIPTION

This is the Baseliner equivalent of TAP's prove script (App::Prove)

Usage, from the command line:

    $ bali prove

    # or

    $ perl script/bali_prove.pl

Basic steps that this script does:

    * Create an empty SQLite Database
    * Execute init.t to create the root user and give him permissions

=head1 OPTIONS

=head2 Run limited test cases

    bali prove --case job [ --case ... ]

=head2 Run only feature tests

    bali prove --feature ca.harvest [ --feature ... ]

=head2 Die on first error found

    bali prove --die

=cut
use v5.10;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$FindBin::Bin/../lib";
use File::Basename;
use Baseliner::Utils;

our $VERSION = 0.02;
our $env;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval nanosleep stat );

BEGIN {
    $env = $ENV{BALI_ENV} ? lc( $ENV{BALI_ENV} ) : 't';
    $ENV{ DBIC_TRACE }                   = 0;
    $ENV{ CATALYST_CONFIG_LOCAL_SUFFIX } = $ENV{BALI_ENV} || 't';
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

say "Baseliner Test Harness v$VERSION";

my %args = _get_options( @ARGV );
if( exists $args{h} ) {  # help
    print << 'EOF';
Usage:
  bali prove [options]

Options:
  -h          : this help
  -case       : run only some test cases (regex)
                  bali prove -case sem -case job
  -feature    : run only certain features (regex)
                  bali prove -feature uploader
  -die        : die on first failed test
  -carp       : use Carp::Always to print error stacks
  -nodeploy   : Prevents the test db creation and schema deploy. Reuse the test db, in case it exists.
  -debug      : Activate the BASELINER_DEBUG flag for extra verbosity.

EOF
    exit 0;
}

my $cnt = 0;
require Carp::Always if exists $args{carp};
$ENV{BASELINER_DEBUG}=1 if exists $args{debug};

# load schema
unless( exists $args{nodeploy} ) {
say pre . "Starting DB deploy...";
require Config::General;
    $Baseliner::Schema::Baseliner::DB_DRIVER = 'SQLite';
require Baseliner::Schema::Baseliner;
my $cfg_file = "$Bin/../baseliner_${env}.conf";
say pre . "Test Environment: $env (config: $cfg_file)";
my $cfg      = Config::General->new( $cfg_file );
    Baseliner::Schema::Baseliner->deploy_schema(
        config      => { $cfg->getall },
        drop        => $env eq 't' ? 1 : 0,
        show_config => 1,
    ) and die pre . "Errors while deploying DB. Aborted\n";

say pre . "Done Deploying DB.";
}

# startup
say pre . "Loading Baseliner...";
require Baseliner;
say pre . "Done loading Baseliner. Version: " . $Baseliner::VERSION;

say pre . "Loading initial values from t/init.t...";
run_test( case=>'t/init.t', force=>1 );
say pre . "Done initializing.";

# find features /t
my @features_list = grep { -e $_ } map { $_->path . '/t' } Baseliner->features->list;

# for each feature /t dir....
my $rc = 0;
my @failed;
foreach my $dir ( "$Bin/../t", @features_list ){
    next if defined $args{ feature }
        && !grep { $dir =~ m{/$_/} } _array( $args{ feature } );
    say pre . "$dir";
    my @cases = <$dir/*.t>;

    for my $t ( sort @cases ) {
        $rc += run_test( case=>$t );
    }
}
say pre . "Done testing. $cnt tests ran. $rc tests failed.";
say "    >>>> $_" for @failed;

exit $rc;

sub run_test {
    my %p = @_;
    my $t = $p{case} or die pre . "*** Missing test case\n";
    my $t_base = basename $t;
    # filter case
    return 0 if !$p{force} && defined $args{ case }
        && !grep { $t_base =~ m{$_} } _array( $args{ case } );
    # run forked
    my $pid;
    unless ( $pid = fork ) {
        say pre . "\t" . $t_base;
        my $rc = do $t;
        die $@ if $@;
        exit;
    }
    # wait for results
    my $rc = waitpid $pid, 0;
    $cnt++;
    my $ec = $?;

    push @failed, $t if $ec;
    die pre . "*** Test failed: $t\n"
        if $ec && exists $args{die};
    return $ec ? 1 : 0;
}
