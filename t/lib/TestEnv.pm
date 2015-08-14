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
use local::lib "$root/../../../local/";

sub debug   { }
sub config  { {} }
sub version { '' }

use Test::MockTime ();
use Baseliner::Core::Registry;

BEGIN { $ENV{BALI_FAST}++ }

BEGIN {
    $Baseliner::logger  = sub { };
    $Baseliner::_logger = sub { };
    $Baseliner::config  = sub { {} };

    sub Clarive::config { { mongo => { dbname => 'acmetest' } } }
}

sub setup {
    require Clarive::App;
    $Clarive::app = Clarive::App->new( env => 'acmetest', config => "$root/../data/acmetest.yml" );
    require Clarive::mdb;
    require Clarive::model;
    require Clarive::cache;

    *Baseliner::registry = sub { 'Baseliner::Core::Registry' };
    *Baseliner::config   = sub { {} };
}

1;
