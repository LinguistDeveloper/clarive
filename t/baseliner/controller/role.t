use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MonkeyMock;
use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils ':catalyst';

use Clarive::mdb;

use_ok 'Baseliner::Controller::Role';

subtest 'action_tree: returns action tree' => sub {
    _setup();

    mdb->role->insert(
        {
            id      => '1',
            role    => 'Role',
            actions => [
                {
                    action => 'action.topics.category.view'
                }
            ]
        }
    );

    my $controller = _build_controller( actions => [ { key => 'action.topics.category.view' } ] );

    my $c = _build_c( req => { params => { id_role => '1' } }, authenticate => {} );

    ok $controller->action_tree($c);

    cmp_deeply $c->stash,
      {
        json => [
            {
                'icon'     => '/static/images/icons/action_folder.gif',
                'text'     => 'topics',
                'children' => [
                    {
                        'icon'      => '/static/images/icons/folder.gif',
                        '_modified' => 1,
                        'children'  => [
                            {
                                'icon' => '/static/images/icons/checkbox.png',
                                'text' => undef,
                                'id'   => 'action.topics.category.view',
                                'leaf' => \1,
                                'key'  => 'action.topics.category.view'
                            }
                        ],
                        'key'       => 'action.topics.category',
                        'text'      => 'category',
                        'leaf'      => \0,
                        'draggable' => \0
                    }
                ],
                'leaf'      => \0,
                'draggable' => \0,
                'key'       => 'action.topics'
            }
        ]
      };
};

sub _setup {
    mdb->master->drop;
    mdb->master_rel->drop;
    mdb->master_doc->drop;

    mdb->role->drop;

    TestUtils->setup_registry();
}

sub _build_controller {
    my (%params) = @_;

    my $actions = Test::MonkeyMock->new;
    $actions->mock( list => sub { @{ $params{actions} || [] } } );

    my $controller = Baseliner::Controller::Role->new( application => '' );

    $controller = Test::MonkeyMock->new($controller);
    $controller->mock( _build_model_actions => sub { $actions } );

    return $controller;
}

sub _build_c { mock_catalyst_c(@_); }

done_testing;
