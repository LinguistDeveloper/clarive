package TestEnv;

use strict;
use warnings;

use base 'Exporter';
our @EXPORT = qw(debug config version);

use Cwd ();
my $root;

BEGIN {
    use File::Basename qw(dirname);
    $root = Cwd::realpath( dirname(__FILE__) );
}

use lib "$root/../../lib";

sub debug   { }
sub config  { {} }
sub version { '' }

use Test::MockTime ();
use Path::Class ();
use Baseliner::Core::Registry;

BEGIN { $ENV{BALI_FAST}++ }

BEGIN {
    $Baseliner::logger  = sub { };
    $Baseliner::_logger = sub { };
    $Baseliner::config  = sub { {} };

    sub Clarive::config { { mongo => { dbname => 'acmetest' }, root => Path::Class::dir('root')->absolute } }
}

sub setup {
    my $class = shift;
    my %opts = @_;
    require Clarive::App;
    $Clarive::app = Clarive::App->new( env => 'acmetest', config => "$root/../data/acmetest.yml", %opts );
    require Clarive::mdb;
    require Clarive::model;
    require Clarive::cache;

    *Baseliner::config = sub { {} };
    *Baseliner::app    = sub { {_logger => sub {}}};
}

1;
