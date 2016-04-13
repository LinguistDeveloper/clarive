use strict;
use warnings;

use Test::More;
use TestEnv;
BEGIN { TestEnv->setup }

$Clarive::_no_cache++;
$Baseliner::_no_cache++;

use Baseliner::Role::CI;
use Baseliner::Core::Registry;
use BaselinerX::Type::Event;

use_ok 'Baseliner::Model::Activity';

subtest 'returns empty array ref when activity not found' => sub {
    _setup();

    my $activity = _build_model();

    my $rv = $activity->find_by_mid(999);

    is_deeply $rv, [];
};

subtest 'returns empty array ref when event not found in registry' => sub {
    _setup();

    my $activity = _build_model();

    my $rv = $activity->find_by_mid(907);

    is_deeply $rv, [];
};

subtest 'returns mapped activity' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'event.job.delete', { vars => ['jobname'] } );

    mdb->activity->insert(
        {
            "event_key" => "event.job.delete",
            "ev_level"  => 0,
            "event_id"  => "2016",
            "ts"        => "2014-10-15 11:30:32",
            "vars"      => {
                "id_job"   => "87",
                "ts"       => "2014-10-15 11:30:32",
                "jobname"  => "N.DESA-00000087",
                "bl"       => "DESA",
                "username" => "root"
            },
            "username" => "root",
            "mid"      => "907",
            "level"    => 0,
            "text"     => undef,
            "module"   => "Baseliner::Controller::Job"
        }
    );

    my $activity = _build_model();

    my $rv = $activity->find_by_mid(907);

    is_deeply $rv,
      [
        {
            text     => 'Event event.job.delete occurred',
            ts       => '2014-10-15 11:30:32',
            jobname  => 'N.DESA-00000087',
            username => 'root'
        }
      ];
};

subtest 'find_by_mid: hides event.topic.modify from topic activity' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'event.topic.modify', { vars => ['username', 'topic_name', 'ts'] } );

    mdb->activity->insert(
        {
            "event_key" => "event.topic.modify",
            "ev_level"  => 0,
            "event_id"  => "2017",
            "ts"        => "2013-12-19 21:08:49",
            "vars"      => {
                "username" => "root",
                "topic_name" => "Name Test",
                "ts" => "2013-12-19 21:08:49",
            },
            "username" => "root",
            "mid"      => "908",
            "level"    => 1,
            "text"     => '%1 modified topic',
            "module"   => "Baseliner::Model::Topic"
        },
    );

    my $activity = _build_model();

    my $rv = $activity->find_by_mid( 908, no_ci => 1 );

    is_deeply $rv, [];
};

subtest 'find_by_mid: hides event.ci.* from topic activity' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'event.ci.update', { vars => ['username', 'old_ci', 'new_ci', 'mid'] } );

    mdb->activity->insert(
        {
            "event_key" => "event.ci.update",
            "ev_level"  => 0,
            "event_id"  => "2018",
            "ts"        => "2016-02-24 10:50:47",
            "vars"      => {
                "mid" => "908",
                "new_ci" => undef,
                "old_ci" => undef,
                "username" => "root",
                "ts" => "2016-02-24 10:50:47",
            },
            "username" => "root",
            "mid"      => "908",
            "level"    => 0,
            "text"     => undef,
            "module"   => "/opt/clarive/clarive/lib/Baseliner/Role/CI.pm"
        },
    );

    my $activity = _build_model();

    my $rv = $activity->find_by_mid( 908, no_ci => 1 );

    is_deeply $rv, [];
};

subtest 'find_by_mid: skips activity with non-zero ev_level' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'event.topic.change_status', {} );

    mdb->activity->insert(
        {
            "event_key" => "event.topic.change_status",
            "ev_level"  => 1,
            "event_id"  => "2017",
            "ts"        => "2013-12-19 21:08:49",
            "vars"      => {
                "username" => "root",
                "topic_name" => "Name Test",
                "ts" => "2013-12-19 21:08:49",
            },
            "username" => "root",
            "mid"      => "908",
            "level"    => 1,
            "text"     => '%1 modified topic',
            "module"   => "Baseliner::Model::Topic"
        },
    );

    my $activity = _build_model();

    my $rv = $activity->find_by_mid( 908, min_level => 5 );

    is_deeply $rv, [];
};

subtest 'find_by_mid: skips activity with undefined ev_level' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'event.topic.change_status', {} );

    mdb->activity->insert(
        {
            "event_key" => "event.topic.change_status",
            "ev_level"  => undef,
            "event_id"  => "2017",
            "ts"        => "2013-12-19 21:08:49",
            "vars"      => {
                "username" => "root",
                "topic_name" => "Name Test",
                "ts" => "2013-12-19 21:08:49",
            },
            "username" => "root",
            "mid"      => "908",
            "level"    => 0,
            "text"     => '%1 modified topic',
            "module"   => "Baseliner::Model::Topic"
        },
    );

    my $activity = _build_model();

    my $rv = $activity->find_by_mid( '908', min_level => 5 );

    is scalar @$rv, 1;
};

sub _setup {
    Baseliner::Core::Registry->clear;
    Baseliner::Core::Registry->add_class( 'main', 'event' => 'BaselinerX::Type::Event' );

    mdb->activity->drop;
}

sub _build_model {
    return Baseliner::Model::Activity->new();
}

done_testing;

1;
