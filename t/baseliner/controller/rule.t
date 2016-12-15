use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils ':catalyst', 'mock_time';
use TestSetup;

use JSON ();
use Capture::Tiny qw(capture);
use Baseliner::Core::Registry;
use Baseliner::Utils qw(_load);

use_ok 'Baseliner::Controller::Rule';

subtest 'save: gets error message when rule is created if the rule is duplicated' => sub {
    _setup();

    my $c = mock_catalyst_c(
        username => 'user',
        req      => {
            params => {
                rule_id   => '',
                rule_name => 'Rule Name',
                rule_type => 'report',
                rule_when => 'post-offline',
                rule_desc => 'Rule Desc',
                rule_tree => []
            }
        }
    );

    my $id_rule = TestSetup->create_rule(
        rule_name => 'Rule Name',
        rule_type => 'report',
        rule_when => 'post-offline',
        rule_desc => 'Rule Desc',
        rule_tree => []
    );

    my $controller = _build_controller();

    $controller->save($c);

    my $result = $c->stash->{json};

    cmp_deeply $result,
        {
        success    => \0,
        msg        => "The rule of type `report` already exists with name `Rule Name`, please introduce another name",
        error_type => "duplicate_rule_name"
        };
};

subtest 'save: gets error message when rule is updated if the rule is duplicated' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule(
        rule_name => 'Rule Name',
        rule_type => 'report',
        rule_when => 'post-offline',
        rule_desc => 'Rule Desc',
        rule_tree => []
    );

    my $id_rule1 = TestSetup->create_rule(
        rule_name => 'Rule Name',
        rule_type => 'pipeline',
        rule_when => 'post-offline',
        rule_desc => 'Rule Desc',
        rule_tree => []
    );

    my $c = mock_catalyst_c(
        username => 'user',
        req      => {
            params => {
                rule_id   => $id_rule1,
                rule_name => 'Rule Name',
                rule_type => 'report',
                rule_when => 'post-offline',
                rule_desc => 'Rule Desc',
                rule_tree => []
            }
        }
    );

    my $controller = _build_controller();

    $controller->save($c);

    my $result = $c->stash->{json};

    cmp_deeply $result,
        {
        success    => \0,
        msg        => "The rule of type `report` already exists with name `Rule Name`, please introduce another name",
        error_type => "duplicate_rule_name"
        };
};

subtest 'palette: returns fieldlets with active set to true' => sub {
    _setup();

    my $c = mock_catalyst_c();

    my $controller = _build_controller();

    $controller->palette($c);

    my @value = $c->stash->{json};
    my ($element) = grep { $_->{text} eq 'Fieldlets' } @{ $c->stash->{json} };

    cmp_deeply $element->{'children'}[0]->{active}, \1;
};

subtest 'palette: returns one element when show_in_palette = 1' => sub {
    _setup();

    #_register_fieldlet(show_in_palette => 1);

    my $c = mock_catalyst_c( req => {} );

    my $controller = _build_controller();

    $controller->palette($c);

    my @elements = grep { $_->{text} eq 'Fieldlets' } @{ $c->stash->{json} };

    ok grep { $_->{key} eq 'fieldlet.in_palette' } @{$elements[0]->{children}};
};

subtest 'palette: returns no elements when show_in_palette = 0' => sub {
    _setup();

    my $c = mock_catalyst_c();

    my $controller = _build_controller();

    $controller->palette($c);

    my @elements = grep { $_->{text} eq 'Fieldlets' } @{ $c->stash->{json} };

    ok !grep { $_->{key} eq 'fieldlet.not_in_palette' } @{$elements[0]->{children}};
};

subtest 'palette: basic tree parents' => sub {
    _setup();

    my $c = mock_catalyst_c(
        username => 'user',
        req      => {
            params => {}
        }
    );

    my $controller = _build_controller();

    $controller->palette($c);

    my @parents = map { $$_{text} } @{ $c->stash->{json} };
    is_deeply \@parents, ['Control', 'Workflow', 'Generic', 'Job', 'Dashlets', 'Fieldlets', 'Rules'];
};

subtest 'palette: children nodes' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'statement.testfoo', { dsl=>sub{} } );
    Baseliner::Core::Registry->add( 'main', 'dashlet.testfoo', { } );
    Baseliner::Core::Registry->add( 'main', 'fieldlet.testfoo', { } );
    Baseliner::Core::Registry->add( 'main', 'fieldlet.notfoo', { show_in_palette=>0 } );
    Baseliner::Core::Registry->add( 'main', 'service.jobfoo', { job_service=>1 } );
    Baseliner::Core::Registry->add( 'main', 'service.genericfoo', { } );

    my $c = mock_catalyst_c(
        username => 'user',
        req      => { params => {} }
    );

    my $controller = _build_controller();

    $controller->palette($c);

    my @json = @{ $c->stash->{json} };
    my @children = map { @{ $$_{children} || [] } } @json;

    ok ! grep { $$_{key} eq 'fieldlet.notfoo' } @children;

    cmp_deeply \@json, supersetof(
        superhashof({ text=>'Control', children=>supersetof( superhashof({ key=>'statement.testfoo' }) ) }),
        superhashof({ text=>'Dashlets', children=>supersetof( superhashof({ key=>'dashlet.testfoo' }) ) }),
        superhashof({ text=>'Fieldlets', children=>supersetof( superhashof({ key=>'fieldlet.testfoo' }) ) }),
        superhashof({ text=>'Generic', children=>supersetof( superhashof({ key=>'service.genericfoo' }) ) }),
        superhashof({ text=>'Job', children=>supersetof( superhashof({ key=>'service.jobfoo' }) ) }),
    );

};

subtest 'palette: reassign children palette' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'statement.testfoo', { dsl=>sub{}, palette_area=>'dashlet' } );
    Baseliner::Core::Registry->add( 'main', 'service.testfoo', { palette_area=>'generic' } );
    Baseliner::Core::Registry->add( 'main', 'service.testbar', { palette_area=>'dashlet' } );

    my $c = mock_catalyst_c(
        username => 'user',
        req      => { params => {} }
    );

    my $controller = _build_controller();

    $controller->palette($c);

    cmp_deeply $c->stash->{json}, supersetof(
        superhashof({ text=>'Dashlets', children=>supersetof( superhashof({ key=>'statement.testfoo' }), superhashof({ key=>'service.testbar' }) ) }),
        superhashof({ text=>'Generic', children=>supersetof( superhashof({ key=>'service.testfoo' }) ) }),
    );

};

subtest 'palette: rules in palette' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule(
        rule_name => 'foorule',
        rule_type => 'independent',
        rule_when => 'post-offline',
        rule_tree => []
    );

    my $c = mock_catalyst_c(
        username => 'user',
        req      => { params => {} }
    );

    my $controller = _build_controller();

    $controller->palette($c);

    cmp_deeply $c->stash->{json}, supersetof(
        superhashof({ text=>'Rules', children=>supersetof( superhashof({ key=>'statement.call', text=>'foorule' }) ) })
    );

};

subtest 'palette: query' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'fieldlet.testfoobar', { name=>'FOOBAR', palette_area=>'fieldlet' } );
    Baseliner::Core::Registry->add( 'main', 'fieldlet.testabcfoo', { name=>'ABCFOO', palette_area=>'fieldlet' } );

    my $c = mock_catalyst_c(
        username => 'user',
        req      => { params => { query=>'FOOBAR' } }
    );

    my $controller = _build_controller();

    $controller->palette($c);

    cmp_deeply $c->stash->{json}, supersetof(
        superhashof({ text=>'Fieldlets', children=>[ superhashof({ text=>'FOOBAR' }) ] })
    );

};

subtest 'list: filters by rule type array' => sub {
    _setup();

    my $id_rule = _create_rule();

    my $c = mock_catalyst_c( req => { params => { } } );
    my $controller = _build_controller();
    $controller->list($c);

    cmp_deeply $c->stash->{json}{data}, [ superhashof({ rule_type=>'independent' }) ];
};

subtest 'list: paging over rules list' => sub {
    _setup();

    for ( my $i = 0; $i < 2; $i++ ) {
        _create_rule();
    }

    my $c = mock_catalyst_c(
        req => {
            params => {
                start     => '0',
                limit     => '1'
            }
        }
    );

    my $controller = _build_controller();
    $controller->list($c);

    is $c->stash->{json}{totalCount}, 2;
    is scalar @{ $c->stash->{json}{data} }, 1;
};

subtest 'grid: filters by rule type array' => sub {
    _setup();

    my $id_rule = _create_rule();

    my $c = mock_catalyst_c( username => 'root', req => { params => { } } );
    my $controller = _build_controller();

    $controller->grid($c);

    cmp_deeply $c->stash->{json}, {
        totalCount=> 1,
        data => ignore()
    };
};

subtest 'stmts_load: returns error when no rule id' => sub {
    _setup();

    my $c = mock_catalyst_c();

    my $controller = _build_controller();

    capture { $controller->stmts_load($c) };

    is_deeply $c->stash,
      {
        'json' => {
            'msg'     => 'Missing rule id',
            'success' => \0
        }
      };
};

subtest 'stmts_load: returns empty rule tree' => sub {
    _setup();

    my $id_rule = _create_rule();

    my $c = mock_catalyst_c( req => { params => { id_rule => $id_rule } } );

    my $controller = _build_controller();

    $controller->stmts_load($c);

    is_deeply $c->stash, { 'json' => [] };
};

subtest 'stmts_load: returns rule tree' => sub {
    _setup();

    my $id_rule = _create_rule(
        rule_tree => [
            {
                "attributes" => {
                    "disabled" => 0,
                    "active"   => 1,
                    "key"      => "statement.step",
                    "text"     => "CHECK",
                    "expanded" => 1,
                    "leaf"     => \0,
                },
                "children" => []
            },
        ]
    );

    my $c = mock_catalyst_c( req => { params => { id_rule => $id_rule } } );

    my $controller = _build_controller();

    $controller->stmts_load($c);

    cmp_deeply $c->stash,
      {
        'json' => [
            {
                'disabled' => \0,
                'text'     => 'CHECK',
                'active'   => 1,
                'expanded' => \1,
                'children' => [],
                'key'      => 'statement.step',
                'leaf'     => JSON::false
            }
        ]
      };
};

subtest 'stmts_load: returns rule tree with versions' => sub {
    _setup();

    my $rule_tree = [
        {
            "attributes" => {
                "disabled" => 0,
                "active"   => 1,
                "key"      => "statement.step",
                "text"     => "CHECK",
                "expanded" => 1,
                "leaf"     => \0,
            },
            "children" => []
        },
    ];
    my $id_rule = _create_rule( rule_tree => $rule_tree );

    mock_time '2016-01-01 12:15:00', sub {
        Baseliner::Model::Rules->new->write_rule(
            id_rule    => $id_rule,
            username   => 'someuser',
            stmts_json => JSON::encode_json($rule_tree)
        );
    };

    mock_time '2016-01-02 12:15:00', sub {
        $rule_tree->[0]->{attributes}->{text} = 'CHECK2';
        Baseliner::Model::Rules->new->write_rule(
            id_rule    => $id_rule,
            username   => 'newuser',
            stmts_json => JSON::encode_json($rule_tree)
        );
    };

    my $c = mock_catalyst_c( req => { params => { id_rule => $id_rule, load_versions => 1 } } );

    my $controller = _build_controller();

    $controller->stmts_load($c);

    cmp_deeply $c->stash,
      {
        'json' => [
            {
                'icon'       => '/static/images/icons/slot.svg',
                'is_current' => \1,
                'text'       => 'Current: 2016-01-02 12:15:00 (newuser)',
                'children'   => [
                    {
                        'disabled' => \0,
                        'text'     => 'CHECK2',
                        'active'   => 1,
                        'expanded' => \1,
                        'children' => [],
                        'key'      => 'statement.step',
                        'leaf'     => JSON::false,
                    }
                ],
                'leaf' => \0
            },
            {
                'icon'     => '/static/images/icons/slot.svg',
                'text'     => 'Version: 2016-01-01 12:15:00 (someuser)',
                'children' => [
                    {
                        'disabled' => \0,
                        'text'     => 'CHECK',
                        'active'   => 1,
                        'expanded' => \1,
                        'children' => [],
                        'key'      => 'statement.step',
                        'leaf'     => JSON::false
                    }
                ],
                'version_id'  => ignore(),
                'version_tag' => '',
                'is_version'  => \1,
                'leaf'        => \0
            }
        ]
      };
};

subtest 'stmts_load: returns rule tree with versions and version tags' => sub {
    _setup();

    my $rule_tree = [
        {
            "attributes" => {
                "disabled" => 0,
                "active"   => 1,
                "key"      => "statement.step",
                "text"     => "CHECK",
                "expanded" => 1,
                "leaf"     => \0,
            },
            "children" => []
        },
    ];
    my $id_rule = _create_rule( rule_tree => $rule_tree );

    mock_time '2015-01-01' => sub {
        Baseliner::Model::Rules->new->write_rule(
            id_rule    => $id_rule,
            username   => 'newuser',
            stmts_json => JSON::encode_json($rule_tree)
        );
    };

    mock_time '2015-01-02' => sub {
        Baseliner::Model::Rules->new->write_rule(
            id_rule    => $id_rule,
            username   => 'anotheruser',
            stmts_json => JSON::encode_json($rule_tree)
        );
    };

    my $version_id =
      mdb->rule_version->find->sort( { ts => 1 } )->next->{_id} . '';

    Baseliner::Model::Rules->tag_version( version_id => $version_id, version_tag => 'production' );

    my $c = mock_catalyst_c( req => { params => { id_rule => $id_rule, load_versions => 1 } } );

    my $controller = _build_controller();

    $controller->stmts_load($c);

    like $c->stash->{json}->[1]->{text}, qr/\[ production \]/;
};

subtest 'rollback_version: rolls back to previous version' => sub {
    _setup();

    my $rule_tree = [
        {
            "attributes" => {
                "disabled" => 0,
                "active"   => 1,
                "key"      => "statement.step",
                "text"     => "CHECK",
                "expanded" => 1,
                "leaf"     => \0,
            },
            "children" => []
        },
    ];
    my $id_rule = _create_rule( rule_tree => $rule_tree );

    mock_time '2016-01-01 12:15:00', sub {
        Baseliner::Model::Rules->new->write_rule(
            id_rule    => $id_rule,
            username   => 'someuser',
            stmts_json => JSON::encode_json($rule_tree)
        );
    };

    mock_time '2016-01-02 12:15:00', sub {
        $rule_tree->[0]->{attributes}->{text} = 'CHECK2';
        Baseliner::Model::Rules->new->write_rule(
            id_rule    => $id_rule,
            username   => 'newuser',
            stmts_json => JSON::encode_json($rule_tree)
        );
    };

    my $version_id =
      mdb->rule_version->find->sort( { ts => 1 } )->next->{_id} . '';

    my $c =
      mock_catalyst_c( req => { params => { version_id => $version_id } } );

    my $controller = _build_controller();

    mock_time '2016-01-03 12:15:00', sub {
        $controller->rollback_version($c);
    };

    cmp_deeply $c->stash,
      {
        'json' => {
            'msg'     => 'Rule rollback to 2016-01-01 12:15:00 (someuser)',
            'success' => \1
        }
      };

    $c = mock_catalyst_c( req => { params => { id_rule => $id_rule, load_versions => 1 } } );
    $controller->stmts_load($c);

    cmp_deeply $c->stash->{json}->[0],
      {
        'icon'       => '/static/images/icons/slot.svg',
        'is_current' => \1,
        'text'       => 'Current: 2016-01-03 12:15:00 (someuser) was: 2016-01-01 12:15:00',
        'children'   => [
            {
                'disabled' => \0,
                'text'     => 'CHECK',
                'active'   => 1,
                'expanded' => \1,
                'children' => [],
                'key'      => 'statement.step',
                'leaf'     => JSON::false
            }
        ],
        'leaf' => \0
      };
};

subtest 'tag_version: tags version' => sub {
    _setup();

    my $rule_tree = [
        {
            "attributes" => {
                "disabled" => 0,
                "active"   => 1,
                "key"      => "statement.step",
                "text"     => "CHECK",
                "expanded" => 1,
                "leaf"     => \0,
            },
            "children" => []
        },
    ];
    my $id_rule = _create_rule( rule_tree => $rule_tree );

    $rule_tree->[0]->{attributes}->{text} = 'CHECK2';
    Baseliner::Model::Rules->new->write_rule(
        id_rule    => $id_rule,
        username   => 'newuser',
        stmts_json => JSON::encode_json($rule_tree)
    );

    my $version_id =
      mdb->rule_version->find->sort( { ts => 1 } )->next->{_id} . '';

    my $c =
      mock_catalyst_c( req => { params => { version_id => $version_id, tag => 'production' } } );

    my $controller = _build_controller();

    $controller->tag_version($c);

    cmp_deeply $c->stash,
      {
        'json' => {
            'msg'     => 'Rule version tagged',
            'success' => \1
        }
      };

    my $rule_version = mdb->rule_version->find_one( { _id => mdb->oid($version_id) } );

    is $rule_version->{version_tag}, 'production';
};

subtest 'tag_version: returns validation errors' => sub {
    _setup();

    my $rule_tree = [
        {
            "attributes" => {
                "disabled" => 0,
                "active"   => 1,
                "key"      => "statement.step",
                "text"     => "CHECK",
                "expanded" => 1,
                "leaf"     => \0,
            },
            "children" => []
        },
    ];
    my $id_rule = _create_rule( rule_tree => $rule_tree );

    $rule_tree->[0]->{attributes}->{text} = 'CHECK2';
    Baseliner::Model::Rules->new->write_rule(
        id_rule    => $id_rule,
        username   => 'newuser',
        stmts_json => JSON::encode_json($rule_tree)
    );

    my $version_id =
      mdb->rule_version->find->sort( { ts => 1 } )->next->{_id} . '';

    my $c =
      mock_catalyst_c( req => { params => { version_id => $version_id } } );

    my $controller = _build_controller();

    $controller->tag_version($c);

    cmp_deeply $c->stash,
      {
        'json' => {
            'msg'    => 'Validation failed',
            'errors' => {
                tag => 'REQUIRED'
            },
            'success' => \0
        }
      };
};

subtest 'untag_version: removes tags version' => sub {
    _setup();

    my $rule_tree = [
        {
            "attributes" => {
                "disabled" => 0,
                "active"   => 1,
                "key"      => "statement.step",
                "text"     => "CHECK",
                "expanded" => 1,
                "leaf"     => \0,
            },
            "children" => []
        },
    ];
    my $id_rule = _create_rule( rule_tree => $rule_tree );

    $rule_tree->[0]->{attributes}->{text} = 'CHECK2';
    Baseliner::Model::Rules->new->write_rule(
        id_rule    => $id_rule,
        username   => 'newuser',
        stmts_json => JSON::encode_json($rule_tree)
    );

    my $version_id =
      mdb->rule_version->find->sort( { ts => 1 } )->next->{_id} . '';

    my $c =
      mock_catalyst_c( req => { params => { version_id => $version_id } } );

    my $controller = _build_controller();

    $controller->untag_version($c);

    cmp_deeply $c->stash,
      {
        'json' => {
            'msg'     => 'Rule version untagged',
            'success' => \1
        }
      };

    my $rule_version = mdb->rule_version->find_one( { _id => mdb->oid($version_id) } );

    ok !exists $rule_version->{version_tag};
};

subtest 'dsl: returns rule dsl' => sub {
    _setup();

    my $rule_tree = [
        {
            "attributes" => {
                "disabled" => 0,
                "active"   => 1,
                "key"      => "statement.step",
                "text"     => "CHECK",
                "expanded" => 1,
                "leaf"     => \0,
            },
            "children" => []
        },
    ];
    my $id_rule = _create_rule( rule_tree => $rule_tree );

    my $stmts = mdb->rule->find_one( { id => "$id_rule" } )->{rule_tree};

    my $c = mock_catalyst_c(
        req => {
            params => {
                stmts     => $stmts,
                id_rule   => $id_rule,
                rule_type => 'independent'
            }
        }
    );

    my $controller = _build_controller();

    $controller->dsl($c);

    cmp_deeply $c->stash,
      {
        json => {
            success   => \1,
            data_yaml => "--- {}\n",
            dsl       => re(qr/current_task\(/)
        }
      };
};

subtest 'dsl_try: runs dsl' => sub {
    _setup();

    my $c = mock_catalyst_c(
        req => {
            params => {
                dsl   => 'do { print "hello"; $stash->{foo} = "bar"; };',
                stash => ''
            }
        }
    );

    my $controller = _build_controller();

    $controller->dsl_try($c);

    cmp_deeply $c->stash,
      {
        json => {
            success    => \1,
            msg        => 'ok',
            output     => 'hello',
            stash_yaml => re(qr/foo: bar/),
        }
      };
};

subtest 'dsl_try: returns compile error' => sub {
    _setup();

    my $c = mock_catalyst_c(
        req => {
            params => {
                dsl   => 'abc',
                stash => ''
            }
        }
    );

    my $controller = _build_controller();

    $controller->dsl_try($c);

    cmp_deeply $c->stash,
      {
        json => {
            success    => \0,
            msg        => re(qr/Bareword "abc" not allowed/),
            stash_yaml => re(qr/---/),
            output     => ''
        }
      };
};

subtest 'dsl_try: returns runtime error' => sub {
    _setup();

    my $c = mock_catalyst_c(
        req => {
            params => {
                dsl   => 'die "error";',
                stash => ''
            }
        }
    );

    my $controller = _build_controller();

    $controller->dsl_try($c);

    cmp_deeply $c->stash,
      {
        json => {
            success    => \0,
            msg        => re(qr/error at/),
            stash_yaml => re(qr/---/),
            output     => ''
        }
      };
};

subtest 'webservice: returns result' => sub {
    _setup();

    my $id_rule = _create_rule(
        rule_active => 1,
        rule_type   => 'independent',
        rule_name   => 'Rule',
        rule_tree   => [
            {
                "attributes" => {
                    "disabled" => 0,
                    "active"   => 1,
                    "key"      => "statement.step",
                    "text"     => "CHECK",
                    "expanded" => 1,
                    "leaf"     => \0,
                },
                "children" => []
            },
        ]
    );

    my $c = mock_catalyst_c( username => 'user' );

    my $controller = _build_controller();

    $controller->default( $c, 'json', $id_rule, 'foo', 'bar' );

    my $stash = $c->stash->{json}->{stash};

    is $stash->{WSURL}, 'http://localhost';
    is_deeply $stash->{ws_headers}, {};
    is_deeply $stash->{ws_arguments}, [qw/foo bar/];
    is $stash->{ws_body}, '';
    is_deeply $stash->{ws_params}, { username => 'user' };
};

subtest 'webservice: setups correct stash values' => sub {
    _setup();

    my $id_rule = _create_rule(
        rule_active => 1,
        rule_type   => 'independent',
        rule_name   => 'Rule',
        rule_tree   => [
            {
                "attributes" => {
                    "disabled" => 0,
                    "active"   => 1,
                    "key"      => "statement.step",
                    "text"     => "CHECK",
                    "expanded" => 1,
                    "leaf"     => \0,
                },
                "children" => []
            },
        ]
    );

    my $c = mock_catalyst_c( username => 'user', req => { uploads => { file => { basename => 'upload.file' } } } );

    my $controller = _build_controller();

    $controller->default( $c, 'json', $id_rule, 'foo', 'bar' );

    my $stash = $c->stash->{json}->{stash};

    is $stash->{WSURL}, 'http://localhost';
    is_deeply $stash->{ws_params}, { username => 'user' };
    is_deeply $stash->{ws_arguments}, [qw/foo bar/];
    is $stash->{ws_uploads}->{file}->basename, 'upload.file';
    is_deeply $stash->{ws_headers}, {};
    is $stash->{ws_body}, '';
};

subtest 'stmts_save: saves statements' => sub {
    _setup();

    my $id_rule = _create_rule(
        rule_active => 1,
        rule_type   => 'independent',
        rule_name   => 'Rule',
    );

    my $c = mock_catalyst_c(
        username => 'user',
        req      => {
            params => {
                id_rule           => $id_rule,
                ignore_dsl_errors => 0,
                stmts             => JSON::encode_json(
                    [
                        {
                            "attributes" => {
                                "disabled" => 0,
                                "active"   => 1,
                                "key"      => "statement.step",
                                "text"     => "CHECK",
                                "expanded" => 1,
                                "leaf"     => \0,
                            },
                            "children" => []
                        },
                    ]
                )
            }
        }
    );

    my $controller = _build_controller();

    $controller->stmts_save($c);

    cmp_deeply $c->stash,
      {
        'json' => {
            'detected_errors' => '',
            'actual_ts'       => ignore(),
            'old_ts'          => ignore(),
            'msg'             => 'Rule statements saved ok',
            'success'         => \1,
            'username'        => 'user'
        }
      };
};

subtest 'stmts_save: returns error when cannot compile dsl' => sub {
    _setup();

    my $id_rule = _create_rule(
        rule_active => 1,
        rule_type   => 'independent',
        rule_name   => 'Rule',
    );

    my $c = mock_catalyst_c(
        username => 'user',
        req      => {
            params => {
                id_rule           => $id_rule,
                ignore_dsl_errors => 0,
                stmts             => JSON::encode_json(
                    [
                        {
                            "attributes" => {
                                "disabled" => 0,
                                "active"   => 1,
                                "key"      => "statement.code",
                                "text"     => "abc",
                                "expanded" => 1,
                                "leaf"     => \0,
                            },
                            "children" => []
                        },
                    ]
                )
            }
        }
    );

    my $controller = _build_controller();

    $controller->stmts_save($c);

    cmp_deeply $c->stash,
      {
        'json' => {
            'msg'                => re(qr/Error testing DSL build: /),
            'success'            => \0,
            'error_checking_dsl' => 0
        }
      };
};

subtest 'default: call a rule as json webservice' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule(
        rule_name => 'ws1',
        rule_type => 'webservice',
        rule_tree => [
            {
                "attributes" => {
                    "icon" => "/static/images/icons/cog_perl.svg",
                    "key"  => "statement.code.server",
                    "text" => "Server CODE",
                    "id"   => "rule-ext-gen38276-1456842988061",
                    "name" => "Server CODE",
                    "data" => {
                        "lang" => "js",
                        "code" => q{
                            var ws = require('cla/ws');
                            var req = ws.request();
                            var res = ws.response();
                            res.data('hola', req.headers('accept-language'));
                            res.content_type('baz');
                        }
                    },
                },
                "children" => [],
            }
        ]
    );

    my $controller = _build_controller();
    my $c          = mock_catalyst_c(
        req => { params => {}, headers => { 'accept-language' => 'foo' }, uri => URI->new('http://localhost') } );
    $c->{username} = 'root';    # change context to root

    $controller->default( $c, 'json', $id_rule );

    my $data = $c->stash->{json};
    is $c->stash->{json}{hola}, 'foo';
    is $c->res->{content_type}, 'baz';
};

subtest 'get_rule_ts: adds ts to json if the rule exists' => sub {
    _setup();

    my $id_rule = _create_rule();

    mock_time '2016-01-01 12:15:00', sub {
        Baseliner::Model::Rules->new->write_rule(
            id_rule  => $id_rule,
            username => 'someuser',
        );
    };

    my $c = mock_catalyst_c( req => { params => { id_rule => $id_rule } } );

    my $controller = _build_controller();

    $controller->get_rule_ts($c);

    is_deeply $c->stash,
        {
        json => {
            ts      => '2016-01-01 12:15:00',
            msg     => 'ok',
            success => \1,
        }
        };
};

subtest 'get_rule_ts: returns error if id_rule is not passed' => sub {
    _setup();

    my $c = mock_catalyst_c( req => { params => { id_rule => '' } } );

    my $controller = _build_controller();

    like exception { $controller->get_rule_ts($c)}, qr/id_rule is not passed/;
};

subtest 'get_rule_ts: returns error if id_rule not exists' => sub {
    _setup();

    my $c = mock_catalyst_c( req => { params => { id_rule => '123' } } );

    my $controller = _build_controller();

    $controller->get_rule_ts($c);

    is_deeply $c->stash,
        {
        json => {
            msg     => 'Rule with id 123 not found',
            success => \0,
        }
        };
};

subtest 'default: croaks on rule_type not webservice or independent' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule(rule_type => 'form');

    my $c = mock_catalyst_c( req => { params => {} } );

    my $controller = _build_controller();

    like exception { $controller->default( $c, 'json', $id_rule )}, qr/Rule $id_rule not independent or webservice: form/;
};

subtest 'default: creates correct event.rule.ws with defined ws_response' => sub {
    _setup();

    my $code = q{ $stash->{ws_response} = { status => 'success'} };
    my $id_rule = TestSetup->create_rule_with_code(
        rule_name => 'ws1',
        rule_type => 'webservice',
        code => $code
    );

    my $c = mock_catalyst_c(
        username => 'root',
        req => { params => {id => 'AAA'} }
    );

    my $controller = _build_controller();
    $controller->default( $c, 'json', $id_rule );

    my $event = mdb->event->find_one( { event_key => 'event.rule.ws' } );
    my $event_data = _load $event->{event_data};

    is $event_data->{username}, 'root';
    is $event_data->{rule_name}, 'ws1';
    is $event_data->{rule_type}, 'webservice';
    is_deeply $event_data->{ws_params}, {
        'id' => 'AAA',
        'username' => 'root'
    };
    is_deeply $event_data->{ws_response}, { "status" => 'success' }
};

subtest 'default: creates correct event.rule.ws with not define ws_response' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule(
        rule_name => 'ws1',
        rule_type => 'webservice'
    );

    my $c = mock_catalyst_c(
        username => 'root',
        req => { params => {id => 'AAA'} }
    );

    my $controller = _build_controller();
    $controller->default( $c, 'json', $id_rule );

    my $event = mdb->event->find_one( { event_key => 'event.rule.ws' } );
    my $event_data = _load $event->{event_data};

    is $event_data->{username}, 'root';
    is $event_data->{rule_name}, 'ws1';
    is $event_data->{rule_type}, 'webservice';
    is_deeply $event_data->{ws_params}, {
        'id' => 'AAA',
        'username' => 'root'
    };
    cmp_deeply $event_data->{ws_response}->{stash} => ignore();
};

subtest 'default: creates correct event.rule.ws with rule error' => sub {
    _setup();

    my $code = q{ ci->user->find({mid => ''wef-122''})->mid" };
    my $id_rule = TestSetup->create_rule_with_code(
        rule_name => 'ws1',
        rule_type => 'webservice',
        code => $code
    );

    my $c = mock_catalyst_c(
        username => 'root',
        req => { params => {id => 'AAA'} }
    );

    my $controller = _build_controller();
    $controller->default( $c, 'json', $id_rule );

    my $event = mdb->event->find_one( { event_key => 'event.rule.ws' } );
    my $event_data = _load $event->{event_data};

    is $event_data->{username}, 'root';
    is $event_data->{rule_name}, 'ws1';
    is $event_data->{rule_type}, 'webservice';
    is_deeply $event_data->{ws_params}, {
        'id' => 'AAA',
        'username' => 'root'
    };
    cmp_deeply $event_data->{ws_response}, {
        Fault => {
            faultactor => 'http://localhost',
            faultcode => '999',
            faultstring => ignore()
        },
        _RETURN_CODE => 404,
        _RETURN_TEXT => 'sorry, not found',
    }
};

subtest 'workflow_rule_tree: returns error if no category_id given' => sub {
    _setup();

    my $c          = mock_catalyst_c();
    my $controller = _build_controller();

    $controller->workflow_rule_tree($c);

    cmp_deeply $c->stash->{json}, {
        success => \0,
        msg     => 'Missing parameter id_category'
    };
};


subtest 'workflow_rule_tree: returns error if category does not exists' => sub {
    _setup();

    my $c = mock_catalyst_c( req => { params => { id_category => '123' } } );
    my $controller = _build_controller();

    $controller->workflow_rule_tree($c);

    cmp_deeply $c->stash->{json}, {
        success => \0,
        msg     => ' rule_id not found'
    };
};

subtest 'workflow_rule_tree: returns workflow rule_tree of category' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_workflow();
    my $id_category = TestSetup->create_category(default_workflow=>$id_rule);
    my $c       = mock_catalyst_c( req => { params => { id_category => $id_category } } );
    my $controller = _build_controller();

    $controller->workflow_rule_tree($c);

    cmp_deeply $c->stash->{json}, {
        success => \1,
        data    => ignore(),
        msg     => "Rule tree of $id_rule loaded successfully"
    };
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Config',
        'BaselinerX::Type::Fieldlet',
        'BaselinerX::Type::Statement',
        'BaselinerX::Type::Service',
        'BaselinerX::Type::Dashlet',
        'BaselinerX::CI',
        'BaselinerX::Fieldlets',
        'Baseliner::Model::Topic',
        'Baseliner::Model::Rules',
        'BaselinerX::Service::ChangesetServices',
        'BaselinerX::Service::CIServices',
        'BaselinerX::Service::CallWebService',
        'BaselinerX::Service::Catalog' ,
        'BaselinerX::Service::CreateJob',
        'BaselinerX::Service::DBServices',
        'BaselinerX::Service::Dispatcher',
        'BaselinerX::Service::FileManagement',
        'BaselinerX::Service::FootprintElements',
        'BaselinerX::Service::Init',
        'BaselinerX::Service::JobDaemon',
        'BaselinerX::Service::LDAPServices',
        'BaselinerX::Service::Parsing',
        'BaselinerX::Service::PauseSuspend',
        'BaselinerX::Service::Purge',
        'BaselinerX::Service::RenameItems',
        'BaselinerX::Service::SchedulerService',
        'BaselinerX::Service::Scripting',
        'BaselinerX::Service::Sed',
        'BaselinerX::Service::ServerService',
        'BaselinerX::Service::Sleep',
        'BaselinerX::Service::SystemMessages',
        'BaselinerX::Service::Templating',
        'BaselinerX::Service::TopicServices',
        'BaselinerX::Service::ValidateStashVariables',
    );

    TestUtils->cleanup_cis;

    Baseliner::Core::Registry->add('BaselinerX::Fieldlet',
        'fieldlet.in_palette' =>
          {name => 'fieldlet.in_palette', show_in_palette => 1});
    Baseliner::Core::Registry->add('BaselinerX::Fieldlet',
        'fieldlet.not_in_palette' =>
          {name => 'fieldlet.not_in_palette', show_in_palette => 0});

    mdb->rule->drop;
    mdb->rule_version->drop;
    mdb->event->drop;
}

sub _create_rule {
    my (%params) = @_;

    if ( $params{rule_tree} && ref $params{rule_tree} ) {
        $params{rule_tree} = JSON::encode_json( $params{rule_tree} );
    }

    my $id_rule = mdb->seq('id');
    mdb->rule->insert(
        {
            id        => "$id_rule",
            rule_seq  => $id_rule,
            rule_type => 'independent',
            rule_active => mdb->true,
            %params,
        }
    );

    return "$id_rule";
}

sub _build_controller {
    Baseliner::Controller::Rule->new( application => '' );
}

sub _register_fieldlet {

    require BaselinerX::Type::Fieldlet;

    Baseliner::Core::Registry->clear();
    Baseliner::Core::Registry->add_class( undef, 'fieldlet' => 'BaselinerX::Type::Fieldlet' );
    Baseliner::Core::Registry->add(
        'BaselinerX::Fieldlet',
        'fieldlet.system.cis' => {
            name => 'cis',
            @_
    });
}
