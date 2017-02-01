use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MonkeyMock;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;
use TestSetup;
use Capture::Tiny qw(capture);

use Baseliner::Utils qw(_load _file);

use_ok 'BaselinerX::Service::CreateJob';

subtest 'run_create: creates a event.job.new with notify' => sub {
    _setup();

    my $id_rule               = TestSetup->create_rule;
    my $id_rule_job           = TestSetup->create_rule_pipeline();
    my $id_changeset_rule     = TestSetup->create_rule_form_changeset();
    my $id_changeset_category = TestSetup->create_category(
        name         => 'Changeset',
        is_changeset => '1',
        id_rule      => $id_changeset_rule,
    );

    my $project       = TestUtils->create_ci('project');
    my $id_role       = TestSetup->create_role( actions => [ { action => 'action.job.create', }, ] );
    my $user          = TestSetup->create_user( id_role => $id_role, project => $project );
    my $changeset_mid = TestSetup->create_topic(
        id_rule     => $id_changeset_rule,
        id_category => $id_changeset_category,
        username    => $user->username,
        project     => $project
    );

    my $bl = TestUtils->create_ci( 'bl', name => 'PROD', bl => 'PROD' );
    my $config = {
        bl         => $bl->{bl},
        changesets => $changeset_mid,
        username   => $user->username,
        id_rule    => $id_rule_job
    };

    my $c = _mock_c( stash => { username => $user->{username} } );

    my $build = _build_create_job();

    capture {
        $build->run_create( $c, $config );
    };

    my $event = mdb->event->find_one( { event_key => 'event.job.new' } );
    my $event_data = _load $event->{event_data};

    cmp_deeply $event_data->{notify},
      {
        project => [ $project->mid ],
        bl      => $bl->{mid}
      };
};

done_testing();

sub _build_create_job {
    return BaselinerX::Service::CreateJob->new();
}

sub _mock_c {
    my (%params) = @_;

    my $c = Test::MonkeyMock->new;
    $c->mock( stash => sub { $params{stash} } );

    return $c;
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event',     'BaselinerX::Type::Action',
        'BaselinerX::Type::Statement', 'BaselinerX::Type::Menu',
        'BaselinerX::Type::Service',   'BaselinerX::Type::Fieldlet',
        'BaselinerX::Type::Config',    'BaselinerX::CI',
        'BaselinerX::Fieldlets',       'BaselinerX::Job',
        'Baseliner::Model::Rules',     'Baseliner::Model::Jobs',
    );

    TestUtils->cleanup_cis;

    mdb->rule->drop;
    mdb->rule_version->drop;
    mdb->role->drop;
    mdb->job_log->drop;
    mdb->category->drop;
    mdb->event->drop;
    mdb->event_log->drop;
}
