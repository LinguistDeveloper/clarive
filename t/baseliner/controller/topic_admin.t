use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
use TestUtils ':catalyst';
use TestSetup;

TestEnv->setup;

use Baseliner::Controller::TopicAdmin;

subtest 'list_status: returns empty json when no ci status' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c();

    $controller->list_status($c);

    my $stash = $c->stash;

    is_deeply $stash, {json => {data => [], totalCount => 0}};
};

subtest 'list_status: returns all ci status when no query' => sub {
    _setup();

    my $controller = _build_controller();

    TestUtils->create_ci('status', name => 'New');

    my $c = _build_c();

    $controller->list_status($c);

    my $stash = $c->stash;

    cmp_deeply $stash, {json => {data => [
        {
                                    'bind_releases' => \0,
                                    'ci_update' => \0,
                                    'name' => 'New',
                                    'description' => undef,
                                    'frozen' => \0,
                                    'readonly' => \0,
                                    'id' => ignore(),
                                    'type' => 'G',
                                    'seq' => undef,
                                    'bl' => '*'
                                  }
        ], totalCount => 1}};
};

subtest 'list_status: returns statuses by category' => sub {
    _setup();

    my $controller = _build_controller();

    my $ci = TestUtils->create_ci('status', name => 'New');
    my $category = mdb->category->insert({name => 'Category', statuses => [$ci->mid]});
    
    TestUtils->create_ci('status', name => 'Something Else');

    my $c = _build_c(req => {params => {category => 'Category'}});

    $controller->list_status($c);

    my $stash = $c->stash;

    is $stash->{json}->{totalCount}, 1;
    is $stash->{json}->{data}->[0]->{id}, $ci->mid;
};

subtest 'list_status: returns statuses by query' => sub {
    _setup();

    my $controller = _build_controller();

    my $ci = TestUtils->create_ci('status', name => 'New');
    
    TestUtils->create_ci('status', name => 'Something Else');

    my $c = _build_c(req => {params => {query => 'New'}});

    $controller->list_status($c);

    my $stash = $c->stash;

    is $stash->{json}->{totalCount}, 1;
    is $stash->{json}->{data}->[0]->{id}, $ci->mid;
};

subtest 'list_status: returns statuses by query and category' => sub {
    _setup();

    my $controller = _build_controller();

    TestUtils->create_ci('status', name => 'Something Else');
    my $ci_new = TestUtils->create_ci('status', name => 'New');
    my $ci_progress = TestUtils->create_ci('status', name => 'Progress');
    my $category = mdb->category->insert({name => 'Category', statuses => [$ci_new->mid, $ci_progress->mid]});

    my $c = _build_c(req => {params => {query => 'New', category => 'Category'}});

    $controller->list_status($c);

    my $stash = $c->stash;

    is $stash->{json}->{totalCount}, 1;
    is $stash->{json}->{data}->[0]->{id}, $ci_new->mid;
};

sub _setup {
    TestUtils->cleanup_cis;
    mdb->category->drop;

    TestUtils->setup_registry('BaselinerX::Type::Event', 'BaselinerX::CI');
}

sub _build_c {
    mock_catalyst_c( @_ );
}

sub _build_controller {
    Baseliner::Controller::TopicAdmin->new( application => '' );
}

done_testing;
