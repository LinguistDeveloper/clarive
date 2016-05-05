use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }

use TestUtils ':catalyst';
use TestSetup;

use Baseliner::Controller::TopicAdmin;

subtest 'list_status: returns empty json when no ci status' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c();

    $controller->list_status($c);

    my $stash = $c->stash;

    is_deeply $stash, {json => {data => [], totalCount => 0}};
};

subtest 'list_status: returns all ci status when no query' => sub {
    _setup();

    my $controller = _build_controller();

    TestUtils->create_ci('status', name => 'New');

    my $c = _build_c();

    $controller->list_status($c);

    my $stash = $c->stash;

    cmp_deeply $stash, {json => {data => [
        {
                                    'bind_releases' => \0,
                                    'ci_update' => \0,
                                    'name' => 'New',
                                    'description' => undef,
                                    'frozen' => \0,
                                    'readonly' => \0,
                                    'id' => ignore(),
                                    'type' => 'G',
                                    'seq' => undef,
                                    'bl' => '*'
                                  }
        ], totalCount => 1}};
};

subtest 'list_status: returns statuses by category' => sub {
    _setup();

    my $controller = _build_controller();

    my $ci = TestUtils->create_ci('status', name => 'New');
    my $category = mdb->category->insert({name => 'Category', statuses => [$ci->mid]});

    TestUtils->create_ci('status', name => 'Something Else');

    my $c = _build_c(req => {params => {category => 'Category'}});

    $controller->list_status($c);

    my $stash = $c->stash;

    is $stash->{json}->{totalCount}, 1;
    is $stash->{json}->{data}->[0]->{id}, $ci->mid;
};

subtest 'list_status: returns statuses by query' => sub {
    _setup();

    my $controller = _build_controller();

    my $ci = TestUtils->create_ci('status', name => 'New');

    my $c = _build_c(req => {params => {query => 'New'}});

    $controller->list_status($c);

    my $stash = $c->stash;

    is $stash->{json}->{totalCount}, 1;
    is $stash->{json}->{data}->[0]->{id}, $ci->mid;
};

subtest 'list_status: returns statuses by query and category' => sub {
    _setup();

    my $controller = _build_controller();

    TestUtils->create_ci('status', name => 'Something Else');
    my $ci_new = TestUtils->create_ci('status', name => 'New');
    my $ci_progress = TestUtils->create_ci('status', name => 'Progress');
    my $category = mdb->category->insert({name => 'Category', statuses => [$ci_new->mid, $ci_progress->mid]});

    my $c = _build_c(req => {params => {query => 'New', category => 'Category'}});

    $controller->list_status($c);

    my $stash = $c->stash;

    is $stash->{json}->{totalCount}, 1;
    is $stash->{json}->{data}->[0]->{id}, $ci_new->mid;
};

subtest 'update_category: changes the color of category and topics that belong to it' => sub {
    _setup();

    my $controller = _build_controller();
    my $project    = TestUtils->create_ci( 'project', name => 'Project', );
    my $id_role    = TestSetup->create_role(
        actions => [
            {   action => 'action.topics.issue.edit',
                bl     => '*'
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );
    my $status = TestUtils->create_ci( 'status', name => 'New' );

    my $form = _create_form();

    my $category_id = TestSetup->create_category(
        name      => 'Category',
        id_rule   => $form,
        id_status => $status->mid,
        color     => '#42FF02'
    );

    my $topic = TestSetup->create_topic(
        id_category    => $category_id,
        title          => 'Test_color',
        color_category => '#42FF02'
    );

    my $c = _build_c(
        req => {
            params => {
                action         => 'update',
                idsstatus      => $status->mid,
                type           => 'N',
                id             => $category_id,
                name           => 'Category',
                category_color => '#FF0202'
            }
        }
    );

    $controller->update_category($c);

    is $c->stash->{json}->{msg}, 'Category modified';

    my $check_color = mdb->topic->find_one( { category_id => $category_id } );
    is $check_color->{color_category} , '#FF0202';
};

sub _create_form {
    return TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        id_field       => 'Status',
                        "bd_field"     => "id_category_status",
                        "fieldletType" => "fieldlet.system.status_new",
                        "id_field"     => "status_new",
                    },
                    "key" => "fieldlet.system.status_new",
                    name  => 'Status',
                }
            }
        ],
    );
}

sub _setup {
    TestUtils->cleanup_cis;
    TestUtils->setup_registry(
        'BaselinerX::Type::Event',
        'BaselinerX::CI',
        'BaselinerX::Type::Fieldlet',
        'BaselinerX::Fieldlets',
        'Baseliner::Model::Topic',
    );
    mdb->topic->drop;
    mdb->role->drop;
    mdb->rule->drop;
    mdb->category->drop;
}

sub _build_c {
    mock_catalyst_c( @_ );
}

sub _build_controller {
    Baseliner::Controller::TopicAdmin->new( application => '' );
}

done_testing;
