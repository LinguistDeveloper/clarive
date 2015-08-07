use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MonkeyMock;
use Test::MockSleep;

use lib 't/lib';
use TestEnv;

TestEnv->setup;

use POSIX ":sys_wait_h";
use JSON ();
use Baseliner::Role::CI;
use Baseliner::Model::Topic;
use Baseliner::RuleFuncs;
use Baseliner::Core::Registry;
use BaselinerX::Type::Event;
use BaselinerX::Type::Fieldlet;
use BaselinerX::Fieldlets;
use Baseliner::Queue;

subtest 'merge_data' => sub {
    _setup();

    my $dest = {};

    my $res = merge_data $dest, { foo => 'bar' }, { bar => 'baz' };

    is_deeply $res, { foo => 'bar', bar => 'baz' };
};

subtest 'merge_data: parses variables' => sub {
    _setup();

    my $dest = {};

    my $res = merge_data $dest, { 'foo' => '${bar}', bar => 'baz' };

    is_deeply $res, { foo => 'baz', bar => 'baz' };
};

subtest 'merge_into_stash' => sub {
    _setup();

    my $stash = {};

    merge_into_stash $stash, { foo => 'bar' };

    is_deeply $stash, { foo => 'bar' };
};

subtest 'current_task' => sub {
    _setup();

    my $run_me;
    my $stash = { var => 'surprise' };

    current_task( $stash, 1, 'some rule', 'some task with ${var}', sub { $run_me++ } );

    is $stash->{current_rule_id},   1;
    is $stash->{current_rule_name}, 'some rule';
    is $stash->{current_task_name}, 'some task with surprise';
};

subtest 'current_task starts task' => sub {
    _setup();

    my $job = Test::MonkeyMock->new;
    $job->mock( start_task => sub { } );

    my $stash = { job => $job };

    current_task( $stash, 1, 'some rule', 'some task with ${var}' );

    ok $job->mocked_called('start_task');
};

subtest 'launch' => sub {
    _setup();

    my $config = {};
    my $stash  = {};

    Baseliner::Core::Registry->add( 'TestService', 'service.scripting.local', { foo => 'bar' } );

    my $rv = launch( 'service.scripting.local', 'some task', $stash, $config, '' );

    is $rv, 'from TestService';
};

subtest 'changeset_projects from data' => sub {
    _setup();

    mdb->topic->drop;
    mdb->master->drop;
    mdb->master_doc->drop;
    mdb->master_rel->drop;
    mdb->category->drop;
    mdb->rule->drop;

    Baseliner::Core::Registry->add_class( undef, 'event'    => 'BaselinerX::Type::Event' );
    Baseliner::Core::Registry->add_class( undef, 'fieldlet' => 'BaselinerX::Type::Fieldlet' );

    Baseliner::Core::Registry->add( 'caller', 'event.topic.create', {} );

    Baseliner::Core::Registry->add(
        'caller',
        'fieldlet.system.status_new' => {
            bd_field  => 'id_category_status',
            id_field  => 'status_new',
            origin    => 'system',
            meta_type => 'status'
        }
    );

    Baseliner::Core::Registry->add(
        'caller',
        'fieldlet.required.category' => {
            id_field => 'category',
            bd_field => 'id_category',
            origin   => 'system',
        }
    );

    Baseliner::Core::Registry->add(
        'caller',
        'fieldlet.system.projects' => {
            get_method => 'get_projects',
            set_method => 'set_projects',
            meta_type  => 'project',
            relation   => 'system',
        }
    );

    my $status_id = ci->status->new( type => 'I' )->save;

    my $id_rule = mdb->seq('id');
    mdb->rule->insert(
        {
            id        => "$id_rule",
            ts        => '2015-08-06 09:44:30',
            rule_type => "form",
            rule_seq  => $id_rule,
            rule_tree => JSON::encode_json(
                [
                    {
                        "attributes" => {
                            "data" => {
                                "bd_field"     => "id_category_status",
                                "name_field"   => "Status",
                                "fieldletType" => "fieldlet.system.status_new",
                                "id_field"     => "status_new",
                            },
                            "key" => "fieldlet.system.status_new",
                        }
                    },
                    {
                        "attributes" => {
                            "data" => {
                                "bd_field"     => "project",
                                "fieldletType" => "fieldlet.system.projects",
                                "id_field"     => "project",
                            },
                            "key" => "fieldlet.system.projects",
                        }
                    }
                ]
            )
        }
    );

    my $cat_id = mdb->seq('id');
    mdb->category->insert(
        { id => "$cat_id", name => 'Category', statuses => [$status_id], default_form => "$id_rule" } );

    my $project = ci->project->new( name => 'Project' );
    my $project_mid = $project->save;

    my $params = {
        'project'    => $project_mid,
        'category'   => "$cat_id",
        'status_new' => "$status_id",
        'action'     => 'add',
    };

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update($params);

    my $stash = { changesets => [$topic_mid] };

    my @projects = changeset_projects($stash);

    is scalar @projects, 1;
    is $projects[0]->{name}, 'Project';
};

subtest 'error_trap: does nothing when ok' => sub {
    _setup();

    my $job = Test::MonkeyMock->new;
    $job->mock( rollback => sub { } );

    my $stash = { job => $job };

    my $rv = error_trap( $stash, 1, 'action', 'do_rollback', 'ignore', sub { 'ok' } );

    ok !$job->mocked_called('rollback');
};

subtest 'error_trap: on error returns nothing when no job provided' => sub {
    _setup();

    my $stash = {};

    my $rv = error_trap( $stash, 1, 'action', 'do_rollback', 'ignore', sub { die 'error' } );

    ok !defined $rv;
};

subtest 'error_trap: on error fail if rollback and no rollback flag' => sub {
    _setup();

    my $job_logger = _mock_job_logger();

    my $job = Test::MonkeyMock->new;
    $job->mock( rollback => sub { 1 } );
    $job->mock( logger   => sub { $job_logger } );

    my $stash = { job => $job };

    like exception {
        error_trap( $stash, 1, 'action', 0, 'ignore', sub { die 'error' } )
    }, qr/error/;
};

subtest 'error_trap: returns undef on ignore' => sub {
    _setup();

    my $job_logger = _mock_job_logger();

    my $job = Test::MonkeyMock->new;
    $job->mock( rollback => sub { 1 } );
    $job->mock( logger   => sub { $job_logger } );

    my $stash = { job => $job };

    ok !defined error_trap( $stash, 1, 'action', 1, 'ignore', sub { die 'error' } );
};

subtest 'error_trap: creates event' => sub {
    _setup();

    Baseliner::Core::Registry->add_class( 'main', 'event', 'BaselinerX::Type::Event' );
    Baseliner::Core::Registry->add( 'main', 'event.rule.trap', {} );

    my $job_logger = _mock_job_logger();

    my $job = Test::MonkeyMock->new;
    $job->mock( rollback    => sub { 0 } );
    $job->mock( logger      => sub { $job_logger } );
    $job->mock( update      => sub { } );
    $job->mock( load        => sub { { status => 'SKIPPING' } } );
    $job->mock( trap_action => sub { } );

    my $stash = { job => $job };

    error_trap( $stash, 1, 'action', 1, '', sub { die 'error' } );

    my $event = mdb->event->find_one;

    is $event->{event_key}, 'event.rule.trap';
};

#subtest 'error_trap: traps action if timeout expired' => sub {
#    _setup();
#
#    Baseliner::Core::Registry->add_class( 'main', 'event', 'BaselinerX::Type::Event' );
#    Baseliner::Core::Registry->add( 'main', 'event.rule.trap', {} );
#
#    my $job_logger = _mock_job_logger();
#
#    my $trapped = 0;
#
#    my $job = Test::MonkeyMock->new;
#    $job->mock( rollback    => sub { 0 } );
#    $job->mock( logger      => sub { $job_logger } );
#    $job->mock( update      => sub { } );
#    $job->mock( load        => sub { { status => 'TRAPPED' } } );
#    $job->mock( trap_action => sub { $trapped++ } );
#
#    my $stash = { job => $job };
#
#    error_trap( $stash, 1, 'action', 1, '', sub { die 'error' } );
#
#    ok $trapped;
#};

subtest 'parralel_run: runs task in background' => sub {
    _setup();

    my $stash = {};

    parallel_run( 'task', 'fork', $stash, sub { 'return from fork' } );

    my $data;
    for my $pid ( keys %{ $stash->{_forked_pids} || {} } ) {
        waitpid $pid, 0;

        $data = queue->pop( msg => "rule:child:results:$pid" );
    }

    is_deeply $data, { ret => 'return from fork', err => undef };
};

subtest 'parralel_run: catches errors' => sub {
    _setup();

    my $stash = {};

    parallel_run( 'task', 'fork', $stash, sub { die 'error from fork' } );

    my $data;
    for my $pid ( keys %{ $stash->{_forked_pids} || {} } ) {
        waitpid $pid, 0;

        $data = queue->pop( msg => "rule:child:results:$pid" );
    }

    cmp_deeply $data, { ret => undef, err => re(qr/error from fork/) };
};

done_testing;

sub _mock_job_logger {
    my $job_logger = Test::MonkeyMock->new;
    $job_logger->mock( info  => sub { } );
    $job_logger->mock( debug => sub { } );
    $job_logger->mock( error => sub { } );

    return $job_logger;
}

sub _setup {
    mdb->event->drop;

    mdb->queue->drop;

    Baseliner::Core::Registry->clear;
}

package TestService;

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    return $self;
}
sub run_container { 'from TestService' }
