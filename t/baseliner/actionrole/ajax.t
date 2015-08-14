use strict;
use warnings;

use lib 't/lib';

use Test::More;
use TestEnv;
use TestUtils ':catalyst';

BEGIN {
    TestEnv->setup;
}

use_ok 'Baseliner::ActionRole::Ajax';

subtest 'returns 1 when called without ajax header but not configured' => sub {
    my $c = mock_catalyst_c();

    my $action = _build_action();

    ok $action->match($c);
    ok $action->match_captures($c);
};

subtest 'returns 0 when called without ajax header' => sub {
    my $c = mock_catalyst_c();

    $c->config->{deny_non_ajax_access}++;

    my $action = _build_action();

    ok !$action->match($c);
    ok !$action->match_captures($c);
};

subtest 'returns 1 when called with ajax header' => sub {
    my $c = mock_catalyst_c( req => { headers => { 'X-Requested-With' => 'XMLHttpRequest' } } );

    $c->config->{deny_non_ajax_access}++;

    my $action = _build_action();

    ok $action->match($c);
    ok $action->match_captures($c);
};

sub _build_action {
    my $meta = Moose::Meta::Class->initialize('TestAction')->create_anon_class(
        superclasses => ['TestAction'],
        roles        => ['Baseliner::ActionRole::Ajax'],
        cache        => 1,
    );

    return $meta->name->new;
}

done_testing;

package TestAction;
use Moose;
BEGIN { extends 'Catalyst::Action' }

sub match          { 1 }
sub match_captures { 1 }
