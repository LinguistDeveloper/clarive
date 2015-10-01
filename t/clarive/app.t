use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;

use Cwd ();
my $root;

BEGIN {
    use File::Basename qw(dirname);
    $root = Cwd::realpath( dirname(__FILE__) );
}

use lib "$root/../../lib";
use local::lib "$root/../../../local/";

use Clarive::App;

subtest 'merges args with config' => sub {
    my $app = Clarive::App->new( config => "$root/../data/acmetest.yml", foo=>'bar' );
    is $app->args->{foo}, 'bar';
    is $app->config->{foo}, 'bar';
};

subtest 'config resolves variables' => sub {
    my $app = Clarive::App->new( config => "$root/../data/acmetest.yml", foo=>'bar', foo2=>'{{foo}}' );
    is $app->config->{foo2}, 'bar';
};

done_testing;
