use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MonkeyMock;
use Test::MockSleep;
use Test::TempDir::Tiny;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils qw(:catalyst mock_time);
use TestSetup;

use_ok 'Baseliner::Controller::Variable';

subtest 'options: returns options of the variable when it is a combo' => sub {
    _setup();

    my $variable = TestUtils->create_ci(
        'variable',
        name              => 'My variable',
        var_type          => 'combo',
        var_combo_options => [ 'one', 'two', 'three' ]
    );
    my $mid = $variable->mid;

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { id => $mid } } );

    $controller->options($c);

    my $data = $c->stash->{json}->{data};

    is $data->[0]->{value}, 'one';
    is $data->[1]->{value}, 'two';
    is $data->[2]->{value}, 'three';
};

subtest 'options: returns options in common bl when the variable is an array' => sub {
    _setup();

    my $variable = TestUtils->create_ci(
        'variable',
        name      => 'My variable',
        var_type  => 'array',
        variables => { '*' => [ 'one', 'two', 'three' ] }
    );

    my $mid = $variable->mid;

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { id => $mid } } );

    $controller->options($c);

    my $data = $c->stash->{json}->{data};

    is $data->[0]->{value}, 'one';
    is $data->[1]->{value}, 'two';
    is $data->[2]->{value}, 'three';
};

subtest 'options: returns options of the variable in correct bl if the variable is an array' => sub {
    _setup();

    my $variable = TestUtils->create_ci(
        'variable',
        name      => 'My variable',
        var_type  => 'array',
        variables => { '*' => [ 'one', 'two', 'three' ], 'DEV' => [ 'four', 'five', 'six' ] }
    );

    my $mid = $variable->mid;

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { id => $mid, bl => 'DEV' } } );

    $controller->options($c);

    my $data = $c->stash->{json}->{data};

    is $data->[0]->{value}, 'four';
    is $data->[1]->{value}, 'five';
    is $data->[2]->{value}, 'six';
};

done_testing;

sub _build_c {
    mock_catalyst_c( username => 'test', @_ );
}

sub _build_controller {
    Baseliner::Controller::Variable->new( application => '' );
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Action',  'BaselinerX::Type::Config',
        'BaselinerX::Type::Event',   'BaselinerX::Type::Fieldlet',
        'BaselinerX::Type::Service', 'BaselinerX::Type::Statement',
        'BaselinerX::CI',            'BaselinerX::Fieldlets',
        'Baseliner::Model::Topic',   'Baseliner::Model::Label',
    );
    TestUtils->cleanup_cis;

    mdb->topic->drop;
    mdb->category->drop;
}
