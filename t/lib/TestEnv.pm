package TestEnv;

use strict;
use warnings;

use base 'Exporter';
our @EXPORT = qw(debug config version);

my $root;
BEGIN {
    use File::Basename qw(dirname);
    $root = dirname(__FILE__);
}

use lib "$root/../../lib";
use local::lib "$root/../../../local/";

sub debug   { }
sub config  { {} }
sub version { '' }

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
}

1;
