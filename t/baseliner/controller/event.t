use strict;
use warnings;

use Test::More;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils qw(:catalyst);

use Baseliner::Core::Registry;
use BaselinerX::Type::Event;

use_ok 'Baseliner::Controller::Event';

subtest 'log: returns events' => sub {
    _setup();

    my $controller = _build_controller();

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

    Baseliner::Core::Registry->add( 'BaselinerX::Type::Event', 'event.topic.change_status', {} );

    my $c = _build_c( req => { params => {} } );

    $controller->log($c);

    is $c->stash->{json}->{totalCount}, 1;
    is $c->stash->{json}->{data}[0]->{event_key}, 'event.topic.change_status';
};

subtest 'log: catches exception when registry is not loaded' => sub {
    _setup();

    my $controller = _build_controller();

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

    my $c = _build_c( req => { params => {} } );

    $controller->log($c);

    my $result = $c->stash->{json}->{data}[0];

    is $c->stash->{json}->{totalCount}, 1;
    is_deeply $result,
      {
        _id         => '3626',
        description => 'Failed to get registry on event: event.topic.change_status'
      };
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Menu',
        'Baseliner::Controller::Event',
    );

    mdb->event->drop;
}

sub _build_controller {
    return Baseliner::Controller::Event->new( application => '' );
}

sub _build_c {
    mock_catalyst_c();
}
