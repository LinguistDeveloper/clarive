package TestEnv;

use strict;
use warnings;

use base 'Exporter';
our @EXPORT = qw(debug config version);

use Cwd ();
my $root;

BEGIN {
    use File::Basename qw(dirname);
    $root = Cwd::realpath(dirname(__FILE__));
}

use lib "$root/../../lib";
use local::lib "$root/../../../local/";

sub debug   { }
sub config  { {} }
sub version { '' }

use Baseliner::Core::Registry;

BEGIN { $ENV{BALI_FAST}++ }
BEGIN {
    $Baseliner::logger = sub {};
    $Baseliner::_logger = sub {};
};

sub setup {
    require Clarive::App;
    $Clarive::app = Clarive::App->new( config => "$root/../data/acmetest.yml" );
    require Clarive::mdb;
    require Clarive::model;
    require Clarive::cache;

    *Baseliner::registry = sub { 'Baseliner::Core::Registry' };
    *Baseliner::config = sub { {} };
    *Baseliner::model = sub {
        shift;
        my ($model) = @_;

        if ($model eq 'ConfigStore') {
            require BaselinerX::Type::Model::ConfigStore;
            return BaselinerX::Type::Model::ConfigStore->new;
        }
    };
}

1;
