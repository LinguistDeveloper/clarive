use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;

use JSON ();
use Baseliner::Utils qw(_load);

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

done_testing;

sub _setup {
    TestUtils->setup_registry( 'BaselinerX::Type::Event', 'Baseliner::Model::Topic' );
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

    return $data;
}
