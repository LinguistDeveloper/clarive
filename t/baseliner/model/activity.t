use strict;
use warnings;

use Test::More;

use lib 't/lib';
use TestEnv;
use Baseliner::Core::Registry;

TestEnv->setup;

use_ok 'Baseliner::Model::Activity';

subtest 'returns empty array ref when activity not found' => sub {
    _setup();

    my $activity = _build_model();

    my $rv = $activity->find_not_cached(999);

    is_deeply $rv, [ ];
};

subtest 'returns empty array ref when event not found in registry' => sub {
    _setup();

    my $activity = _build_model();

    my $rv = $activity->find_not_cached(907);

    is_deeply $rv, [ ];
};

subtest 'returns mapped activity' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'TestEvent', 'event.job.delete', { vars => ['jobname'] } );

    my $activity = _build_model();

    my $rv = $activity->find_not_cached(907);

    is_deeply $rv,
      [
        {
            text     => '',
            ts       => '2014-10-15 11:30:32',
            jobname  => 'N.DESA-00000087',
            username => 'root'
        }
      ];
};

sub _setup {
    Baseliner::Core::Registry->clear;

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
