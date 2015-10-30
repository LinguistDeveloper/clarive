use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MonkeyMock;
use Test::MockSleep;

use TestEnv;
use TestUtils ':catalyst';
use TestSetup qw(_topic_setup _setup_clear _setup_user);

TestEnv->setup;

use POSIX ":sys_wait_h";
use Baseliner::Role::CI;
use Baseliner::Model::Topic;
use Baseliner::RuleFuncs;
use Baseliner::Core::Registry;
use BaselinerX::Type::Event;
use BaselinerX::Fieldlets;
use Baseliner::Queue;

use Baseliner::Controller::Topic;
use Baseliner::Model::Topic;
use Class::Date;

subtest 'kanban config save' => sub {
    _setup_clear();
    _setup_user();
    my $base_params = _topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update({ %$base_params, action=>'add' });
    my $controller = _build_controller();
    my $c = _build_c( req => { params => { mid=>$topic_mid, statuses=>[ $base_params->{status_new} ]  } } );
    $controller->kanban_config($c);
    ok ${ $c->stash->{json}{success} };

    $c = _build_c( req => { params => { mid=>$topic_mid } } );
    $controller->kanban_config( $c );
    is $c->stash->{json}{config}{statuses}->[0], $base_params->{status_new};
};

subtest 'kanban no config, default' => sub {
    _setup_clear();
    _setup_user();
    my $base_params = _topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update({ %$base_params, action=>'add' });
    my $controller = _build_controller();
    my $c = _build_c( req => { params => { mid=>$topic_mid } } );
    $controller->kanban_config($c);
    is keys %{ $c->stash->{json}{config} }, 0;
};

subtest 'next status for topic by root user' => sub {
    _setup_clear();
    _setup_user();
    my $base_params = _topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update({ %$base_params, action=>'add' });
    my $id_status_from = $base_params->{status_new};
    my $id_status_to   = ci->status->new( name=>'Dev', type => 'I' )->save;

    # create a workflow
    my $workflow = [{ id_role=>'1', id_status_from=> $id_status_from, id_status_to=>$id_status_to, job_type=>undef }];
    mdb->category->update({ id=>"$base_params->{category}" },{ '$set'=>{ workflow=>$workflow }, '$push'=>{ statuses=>$id_status_to } });

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { topic_mid=>"$topic_mid" } } );
    $c->{username} = 'root'; # change context to root
    $controller->list_admin_category($c);
    my $data = $c->stash->{json}{data};

    # 2 rows, root can take the topic 
    is $data->[0]->{status}, $id_status_from;
    is $data->[1]->{status}, $id_status_to;
};

############ end of tests

sub _build_c {
    mock_catalyst_c( username => 'test', @_ );
}

sub _build_controller {
    Baseliner::Controller::Topic->new( application => '' );
}

done_testing;

