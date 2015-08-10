use strict;
use warnings;

use Test::More;

use lib 't/lib';
use TestEnv;
use Baseliner::Core::Registry;

TestEnv->setup;

$Clarive::_no_cache++;
$Baseliner::_no_cache++;

use Baseliner::Role::CI;
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

sub _setup {
    Baseliner::Core::Registry->clear;

    Baseliner::Core::Registry->add_class( 'main', 'event' => 'BaselinerX::Type::Event' );

    mdb->activity->drop;

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
}

sub _build_model {
    return Baseliner::Model::Activity->new();
}

done_testing;

1;
