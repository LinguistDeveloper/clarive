use strict;
use warnings;
use utf8;

use Test::More;
use Test::Deep;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use_ok 'Baseliner::Role::CI::Asset';

subtest 'put_data: throws when not saved first' => sub {
    _setup();

    my $object = _build_object();

    like exception { $object->put_data() }, qr/MID missing. To put asset data CI must be saved first/;
};

subtest 'put_data: saves data to grid' => sub {
    _setup();

    my $object = _build_object();

    my $mid = $object->save;

    $object->put_data('foo');

    my $grid = $object->get_data;

    my $info = $grid->info;

    is $grid->slurp, 'foo';
    is $info->{length},            3;
    is $info->{parent_mid},        $mid;
    is $info->{parent_collection}, 'TestObject';
};

subtest 'put_data: replaces the previous data' => sub {
    _setup();

    my $object = _build_object();

    my $mid = $object->save;

    $object->put_data('foo');
    $object->put_data('bar');

    my $grid = $object->get_data;

    my $info = $grid->info;

    is $info->{length}, 3;
    is $grid->slurp, 'bar';
};

subtest 'put_data: saves unicode data to grid' => sub {
    _setup();

    my $object = _build_object();

    my $mid = $object->save;

    $object->put_data('привет');

    my $grid = $object->get_data;

    my $info = $grid->info;

    is $info->{length}, 12;
    is Encode::decode( 'UTF-8', $grid->slurp ), 'привет';
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::CI',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Statement',
        'BaselinerX::Type::Service',
        'Baseliner::Model::Jobs',
        'Baseliner::Model::Rules' );

    mdb->rule->drop;
    mdb->topic->drop;
    mdb->category->drop;

    TestUtils->cleanup_cis;
}

{

    package TestObject;
    use Moose;

    BEGIN {
        sub icon { '123' }
        with 'Baseliner::Role::CI::Asset';
    }
}

sub _build_object { TestObject->new }
