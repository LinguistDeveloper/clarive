use strict;
use warnings;
use utf8;

use Test::More;
use Test::Deep;
use Test::Fatal;
use Test::MonkeyMock;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;

use JSON ();
use File::Temp;
use Baseliner::Utils qw(_load _file);

use_ok 'Baseliner::Model::TopicExporter';

subtest 'export: calls correct exporter' => sub {
    _setup();

    my $exporter = _build_exporter();

    my $content = $exporter->export( 'test', JSON::encode_json( { foo => 'bar' } ) );

    is_deeply $content, {foo => 'bar'};
};

subtest 'export: throws on error' => sub {
    _setup();

    my $exporter = _build_exporter();

    like exception { $exporter->export( 'test', JSON::encode_json( { foo => 'bar' } ), error => 1 ) },
      qr/Export error: error/;
};

subtest 'export: creates event' => sub {
    _setup();

    my $exporter = _build_exporter();

    my $content = $exporter->export(
        'test', JSON::encode_json( { foo => 'bar' } ),
        username => 'user',
        title    => 'Hello',
        params   => JSON::encode_json( { query => 'params' } )
    );

    my $event = mdb->event->find_one;
    ok $event;

    my $event_data = _load $event->{event_data};

    is $event_data->{username},     'user';
    is $event_data->{export_title}, 'Hello';
    is_deeply $event_data->{export_params}, { query => 'params' };
    is $event_data->{export_format}, 'test';
    ok $event_data->{export_temp_file};
};

subtest 'export: removes temp file after event fired' => sub {
    _setup();

    my $exporter = _build_exporter();

    my $content = $exporter->export(
        'test', JSON::encode_json( { foo => 'bar' } ),
        username => 'user',
        title    => 'Hello',
        params   => JSON::encode_json( { query => 'params' } )
    );

    my $event = mdb->event->find_one;

    my $event_data = _load $event->{event_data};

    ok !-f $event_data->{export_temp_file};
};

subtest 'export: correctly saves data to temp file' => sub {
    _setup();

    my $exporter = _build_exporter();
    $exporter = Test::MonkeyMock->new($exporter);
    $exporter->mock( _create_temp_file => sub { File::Temp->new( UNLINK => 0 ) } );

    my $content = $exporter->export(
        'test', JSON::encode_json( { foo => 'bar', data => '123' } ),
        username => 'user',
        title    => 'Hello',
        params   => JSON::encode_json( { query => 'params' } )
    );

    my $event = mdb->event->find_one;

    my $event_data = _load $event->{event_data};

    my $temp_file = $event_data->{export_temp_file};

    my $export = _file($temp_file)->slurp;

    is $export, '123';

    unlink $temp_file;
};

subtest 'export: correctly saves data with unicode to temp file' => sub {
    _setup();

    my $exporter = _build_exporter();
    $exporter = Test::MonkeyMock->new($exporter);
    $exporter->mock( _create_temp_file => sub { File::Temp->new( UNLINK => 0 ) } );

    my $content = $exporter->export(
        'test', JSON::encode_json( { foo => 'bar', data => 'привет' } ),
        username => 'user',
        title    => 'Hello',
        params   => JSON::encode_json( { query => 'params' } )
    );

    my $event = mdb->event->find_one;

    my $event_data = _load $event->{event_data};

    my $temp_file = $event_data->{export_temp_file};

    my $export = _file($temp_file)->slurp;

    is $export, Encode::encode('UTF-8', 'привет');

    unlink $temp_file;
};

subtest 'export: produces correct export using JSON title' => sub {
    _setup();

    my $exporter = _build_exporter();

    my $content = $exporter->export(
        'test', JSON::encode_json( { foo => 'bar' } ),
        username => 'user',
        title    => JSON::encode_json( { categories => 'foo', statuses => 'bar' } ),
        params => JSON::encode_json( { query => 'params' } )
    );

    is_deeply $content, {foo => 'bar'};
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Service',
        'BaselinerX::Type::Statement',
        'Baseliner::Model::Topic',
    );

    TestUtils->cleanup_cis;

    mdb->event->drop;
}

sub _build_exporter {
    Baseliner::Model::TopicExporter->new;
}

package Baseliner::Model::TopicExporter::Test;
use Moose;

sub export {
    my $self = shift;
    my ( $data, %params ) = @_;

    die 'error' if $params{error};

    return $data->{data} if $data->{data};

    return $data;
}
