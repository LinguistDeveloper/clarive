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
use TestSetup;

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
use Clarive::mdb;
use Class::Date;

subtest 'kanban config save' => sub {
    TestSetup->_setup_clear();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

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
    TestSetup->_setup_clear();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update({ %$base_params, action=>'add' });
    my $controller = _build_controller();
    my $c = _build_c( req => { params => { mid=>$topic_mid } } );
    $controller->kanban_config($c);
    is keys %{ $c->stash->{json}{config} }, 0;
};

subtest 'next status for topic by root user' => sub {
    TestSetup->_setup_clear();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

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

subtest 'next status for topics by root user' => sub {
    TestSetup->_setup_clear();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update({ %$base_params, action=>'add' });
    my $id_status_from = $base_params->{status_new};
    my $id_status_to   = ci->status->new( name=>'Dev', type => 'I' )->save;

    # create a workflow
    my $workflow = [{ id_role=>'1', id_status_from=> $id_status_from, id_status_to=>$id_status_to, job_type=>undef }];
    mdb->category->update({ id=>"$base_params->{category}" },{ '$set'=>{ workflow=>$workflow }, '$push'=>{ statuses=>$id_status_to } });

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { topics=>["$topic_mid"] } } );
    $c->{username} = 'root'; # change context to root
    $controller->next_status_for_topics($c);
    my $data = $c->stash->{json}{data};

    is $data->[0]->{id_status_from}, $id_status_from;
    is $data->[0]->{id_status_to}, $id_status_to;
};

subtest 'list statuses fieldlet for new topics not yet in database' => sub {
    TestSetup->_setup_clear();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my $id_status_from = $base_params->{status_new};
    my $id_status_to   = ci->status->new( name=>'Dev', type => 'I' )->save;

    # create a workflow
    my $workflow = [{ id_role=>'1', id_status_from=> $id_status_from, id_status_to=>$id_status_to, job_type=>undef }];
    mdb->category->update({ id=>"$base_params->{category}" },{ '$set'=>{ workflow=>$workflow }, '$push'=>{ statuses=>$id_status_to } });

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { categoryId=>$base_params->{category}, statusId=>$id_status_from } } );
    $c->{username} = 'root'; # change context to root
    $controller->list_admin_category($c);
    my $data = $c->stash->{json}{data};

    # 2 rows, root can take the topic 
    is $data->[0]->{status}, $id_status_from;
    is $data->[1]->{status}, $id_status_to;
};

subtest 'add label to topic' => sub {
    TestSetup->_setup_clear();
    TestSetup->_setup_user();
    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update({ %$base_params, action=>'add' });
    my $label_id = TestSetup->_setup_label;

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { topic_mid=>$topic_mid, label_ids=>["$label_id"] } } );
    $c->{username} = 'root'; # change context to root
    $controller->update_topic_labels($c);
    cmp_deeply( $c->stash, { json => { msg => 'Labels assigned', success => \1 } } );
    is_deeply( mdb->topic->find_one({ mid=>"$topic_mid" })->{labels}, [$label_id] );
};

subtest 'grid: sets correct template' => sub {
    my $controller = _build_controller();

    my $c = _build_c( req => { params => { } } );

    $controller->grid($c);

    is $c->stash->{template}, '/comp/topic/topic_grid.js';
};

subtest 'grid: prepares stash' => sub {
    my $controller = _build_controller();

    my $c = _build_c( req => { params => { } } );

    $controller->grid($c);

    cmp_deeply(
        $c->stash,
        {
            'typeApplication' => undef,
            'template'        => ignore(),
            'query_id'        => undef,
            'project'         => undef,
            'id_project'      => undef
        }
    );
};

subtest 'grid: overrides stash with params' => sub {
    my $controller = _build_controller();

    my $c = _build_c( req => { params => {query => '123', project => '456', id_project => '789' } } );

    $controller->grid($c);

    cmp_deeply(
        $c->stash,
        {
            'typeApplication' => undef,
            'template'        => ignore(),
            'query_id'        => '123',
            'project'         => '456',
            'id_project'      => '789',
        }
    );
};

subtest 'grid: set category_id' => sub {
    my $controller = _build_controller();

    my $c = _build_c( req => { params => {category_id => '123'} } );

    $controller->grid($c);

    is $c->stash->{category_id}, '123';
};

subtest 'grid: replaces category_id if different' => sub {
    my $controller = _build_controller();

    my $c = _build_c( req => { params => {category_id => '123'} } );

    $c->stash->{category_id} = 321;
    $controller->grid($c);

    is $c->stash->{category_id}, '123';
};

############ end of tests


sub _build_c {
    mock_catalyst_c( username => 'test', @_ );
}

sub _build_controller {
    Baseliner::Controller::Topic->new( application => '' );
}

done_testing;
