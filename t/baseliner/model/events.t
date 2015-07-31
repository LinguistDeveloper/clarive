use strict;
use warnings;

use Test::More;

use lib 't/lib';
use TestEnv;
use Baseliner::Core::Registry;

TestEnv->setup;

$Clarive::_no_cache++;
$Baseliner::_no_cache++;

use_ok 'Baseliner::Model::Events';

subtest 'find_by_key: returns empty array ref when events not found' => sub {
    _setup();

    my $events = _build_model();

    my $rv = $events->find_by_key('foo.bar');

    is_deeply $rv, [ ];
};

subtest 'find_by_key: returns events' => sub {
    _setup();

    my $events = _build_model();

    my $rv = $events->find_by_key('event.topic.change_status');

    is scalar @$rv, 1;
    is $rv->[0]->{mid}, '1479';
    is $rv->[0]->{foo}, 'bar';
};

subtest 'find_by_mid: returns empty array ref when events not found' => sub {
    _setup();

    my $events = _build_model();

    my $rv = $events->find_by_mid(999);

    is_deeply $rv, [ ];
};

subtest 'find_by_mid: returns empty array ref when event not registered' => sub {
    _setup();

    my $events = _build_model();

    my $rv = $events->find_by_mid(1479);

    is_deeply $rv, [ ];
};

subtest 'find_by_mid: returns mapped event' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'TestEvent', 'event.topic.change_status', { vars => ['foo'] } );

    my $events = _build_model();

    my $rv = $events->find_by_mid(1479);

    is_deeply $rv,
      [
        {
            'text'     => '',
            'ts'       => '2015-04-02 15:48:54',
            'foo'      => 'bar',
            'username' => 'clarive'
        }
      ];
};

sub _setup {
    Baseliner::Core::Registry->clear;

    mdb->event->drop;

    mdb->event->insert(
        {
            "event_data"   => "---\nfoo: bar",
            "event_key"    => "event.topic.change_status",
            "event_status" => "ok",
            "ts"           => "2015-04-02 15:48:54",
            "username"     => "clarive",
            "mid"          => "1479",
            "id"           => "3626",
            "t"            => 1427982534.315101,
            "module"       => "Baseliner::Model::Topic"
        }
    );
}

sub _build_model {
    return Baseliner::Model::Events->new();
}

done_testing;

package TestEvent;

sub new {
    my $class = shift;

    my $self = { %{ $_[0] } };
    bless $self, $class;

    return $self;
}

sub vars       { shift->{vars} }
sub event_text { '' }
sub level      { shift->{vars} }

1;
