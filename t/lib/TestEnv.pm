package TestEnv;

use strict;
use warnings;

use base 'Exporter';
our @EXPORT = qw(debug config version);

use Cwd ();
use File::chdir;
my $root;

BEGIN {
    use File::Basename qw(dirname);
    $root = Cwd::realpath( dirname(__FILE__) );
}

use lib "$root/../../lib";

sub debug   { }
sub config  { {} }
sub version { '' }

use Carp qw(longmess);
use Test::MockTime ();
use Cwd ();
use Path::Class    ();
use Baseliner::Core::Registry;

BEGIN { $ENV{BALI_FAST}++ }

BEGIN {
    $Baseliner::logger  = $Clarive::logger  = sub { };
    $Baseliner::_logger = $Clarive::_logger = sub { };
}

my @WARNINGS;

sub setup {
    my $class = shift;
    my %opts  = @_;

    my $prev_dir = Cwd::getcwd();

    $ENV{CLARIVE_ENV} = 'acmetest';

    require Clarive::App;
    $Clarive::app = Clarive::App->new( env => 'acmetest', config => "$root/../data/acmetest.yml", %opts );
    Clarive->config->{root} = Path::Class::dir('root')->absolute;

    chdir $prev_dir;

    require Clarive::mdb;
    require Clarive::model;
    require Clarive::cache;

    *Baseliner::app = sub {
        {
            _logger => sub { }
        };
    };

    mdb->sem->drop;
    mdb->sem_queue->drop;

    mdb->index_all('sem');
    mdb->index_all('master_seq');

    $SIG{__WARN__} = sub {
        push @WARNINGS, longmess( $_[0] );
        warn @_;
    };

    $CWD = $ENV{CLARIVE_HOME};
}

END {
    if ( $ENV{TEST_FATAL_WARNINGS} && @WARNINGS ) {
        print STDERR "WARNINGS!\n";
        for (@WARNINGS) {
            print STDERR "$_\n";
        }

        exit 1;
    }
}

1;
