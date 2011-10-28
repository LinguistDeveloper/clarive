use strict;
use warnings;
use Test::More tests => 24;

BEGIN { use_ok 'Catalyst::Test', 'Baseliner' }
BEGIN { use_ok 'Baseliner::Model::Permissions' }

my $c = Baseliner->new();
my $data = 'abcd';
{
    my $job = $c->model('Baseliner::BaliJob')->search({ id=>205 })->first;
    $job->stash( $data );
}
{
    my $job = $c->model('Baseliner::BaliJob')->search({ id=>205 })->first;
    my $stash_data = $job->stash;
    ok( defined $stash_data, 'stash retrieved');
    is( $stash_data , $data, 'stash data match' );
}
