use strict;
use warnings;

use Test::Deep;
use Test::More;
use Test::LongString;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils qw(mock_time);
use TestSetup;

use Class::Date;
use Time::HiRes qw(usleep);
use JSON ();
use Capture::Tiny qw(capture);
use Baseliner::Role::CI;
use BaselinerX::Type::Statement;
use BaselinerX::Type::Service;
use Baseliner::RuleCompiler;
use Baseliner::RuleRunner;
use Baseliner::Utils qw(_retry);

use_ok 'Baseliner::Model::Rules';

subtest 'check_duplicated_rule: duplicated rule when have same name and same type and no id rule' => sub {
    _setup();

    my $model = _build_model();

    my $rule_id = TestSetup->create_rule( rule_name => 'Rule', rule_type => 'Rule_type' );

    my $exists = $model->check_duplicated_rule( 'Rule', 'Rule_type' );

    ok $exists;
};

subtest 'check_duplicated_rule: not duplicated rule when have same name and same type and same id rule' => sub {
    _setup();

    my $model = _build_model();

    my $rule_id = TestSetup->create_rule( rule_name => 'Rule', rule_type => 'Rule_type' );

    my $exists = $model->check_duplicated_rule( 'Rule', 'Rule_type', $rule_id );

    ok !$exists;
};

subtest 'check_duplicated_rule: duplicated rule when have same name and same type and diferent id rule' => sub {
    _setup();

    my $model = _build_model();

    my $rule_id   = TestSetup->create_rule( rule_name => 'Rule',   rule_type => 'Rule_type' );
    my $rule_id_2 = TestSetup->create_rule( rule_name => 'Rule_2', rule_type => 'Rule_type' );

    my $exists = $model->check_duplicated_rule( 'Rule', 'Rule_type', $rule_id_2 );

    ok $exists;
};

subtest 'does compile when config flag is conditional and rule is on' => sub {
    _setup();

    my $id_rule = _create_rule(rule_compile_mode => 'precompile');
    my $rules = _build_model();

    $rules->compile_rules( rule_precompile => 'depends' );

    my $rule = mdb->rule->find_one({id => $id_rule});
    ok( Baseliner::RuleCompiler->new( id_rule => $id_rule, version_id => '' . $rule->{_id} )->is_loaded );
};

subtest 'does not compile when config flag is conditional and rule is off' => sub {
    _setup();

    my $id_rule = _create_rule(rule_compile_mode => 'none');

    my $rules = _build_model();

    $rules->compile_rules( rule_precompile => 'depends' );

    my $rule = mdb->rule->find_one({id => $id_rule});
    ok(!Baseliner::RuleCompiler->new( id_rule => $id_rule, version_id => '' . $rule->{_id} )->is_loaded );
};

subtest 'does compile when config flag is on and rule is off' => sub {
    _setup();

    my $id_rule = _create_rule();

    my $rules = _build_model();

    $rules->compile_rules( rule_precompile => 'always' );

    my $rule = mdb->rule->find_one({id => $id_rule});
    ok( Baseliner::RuleCompiler->new( id_rule => $id_rule, version_id => '' . $rule->{_id} )->is_loaded );
};

subtest 'does compile when config flag is on and rule is on' => sub {
    _setup();

    my $id_rule = _create_rule(rule_compile_mode => 'precompile');

    my $rules = _build_model();

    $rules->compile_rules( rule_precompile => 'always' );

    my $rule = mdb->rule->find_one({id => $id_rule});
    ok( Baseliner::RuleCompiler->new( id_rule => $id_rule, version_id => '' . $rule->{_id} )->is_loaded );
};

subtest 'does not compile when config flag is off and rule is on' => sub {
    _setup();

    my $id_rule = _create_rule(rule_compile_mode => 'precompile');

    my $rules = _build_model();

    $rules->compile_rules( rule_precompile => 'none' );

    my $rule = mdb->rule->find_one({id => $id_rule});
    ok(!Baseliner::RuleCompiler->new( id_rule => $id_rule, version_id => '' . $rule->{_id} )->is_loaded );
};

subtest 'does not compile when config flag is off and rule is off' => sub {
    _setup();

    my $id_rule = _create_rule(rule_compile_mode => 'none', ts => "2015-06-30 13:44:11" );

    my $rules = _build_model();

    $rules->compile_rules( rule_precompile => 'none' );

    my $rule = mdb->rule->find_one({id => $id_rule});
    ok(!Baseliner::RuleCompiler->new( id_rule => $id_rule, version_id => '' . $rule->{_id} )->is_loaded );
};

subtest 'statement.call' => sub {
    _setup();

    my $statement = TestUtils->registry->registrar->{'statement.call'};

    my $dsl = $statement->{param}->{dsl};

    my $code = $dsl->( undef, { id_rule => ['123'] } );

    my $package = 'test_statement_call_' . int( rand(1000) );

    $code = sprintf q/package %s; use Baseliner::Utils 'parse_vars'; my $stash = {}; sub call { \@_ } sub { %s }/,
      $package, $code;

    $code = eval $code;

    my $args = $code->();

    is $args->[0], '123';
};

subtest 'statement.call with parse_vars' => sub {
    _setup();

    my $statement = TestUtils->registry->registrar->{'statement.call'};

    my $dsl = $statement->{param}->{dsl};

    my $code = $dsl->( undef, { id_rule => '${some_var}' } );

    my $package = 'test_statement_call_' . int( rand(1000) );

    $code =
      sprintf
      q/package %s; use Baseliner::Utils 'parse_vars'; my $stash = {some_var => 'hi!'}; sub call { \@_ } sub { %s }/,
      $package, $code;

    $code = eval $code;

    my $args = $code->();

    is $args->[0], 'hi!';
};

subtest 'statement.parallel.wait: saves result to data_key' => sub {
    _setup();

    my $statement = TestUtils->registry->registrar->{'statement.parallel.wait'};

    my $dsl = $statement->{param}->{dsl};

    my $code = $dsl->( undef, { data_key => 'output' } );

    my $package = 'test_statement_call_' . int( rand(1000) );

    $code = sprintf q/package %s; my $stash = {}; sub wait_for_children { '123' } sub { %s; $stash }/, $package, $code;

    $code = eval $code;

    my $args = $code->();

    is_deeply $args, { output => '123' };
};

subtest 'dsl_build: semaphore key test with fork' => sub {
    _setup();

    mdb->_test_sem->drop;
    mdb->_test_sem->ensure_index( { key => 1 }, { unique => 1 } );
    mdb->index_all('sem');
    mdb->index_all('master_seq');

    my $key = 'test';

    {
        package DummyPKGSemaphore;
        sub new { }
    }

    Baseliner::Core::Registry->add(
        'DummyPKGSemaphore',
        'service.test.op' => {
            name    => 'Test Op',
            handler => sub {
                my ( $self, $c, $config ) = @_;

                my $stash = $c->stash;

                _retry sub {
                    mdb->_test_sem->update( { key => $key }, { '$inc' => { cnt => 1 } }, { upsert => 1 } );
                }, attempts => 3;

                Time::HiRes::usleep( 10_000 * int rand 10 );

                $stash->{sem_cnt} = mdb->_test_sem->find_one->{cnt};
                mdb->_test_sem->update( { key => $key }, { '$inc' => { cnt => -1 } } );

                mdb->disconnect;
            }
        }
    );

    my $rules = _build_model();

    my $dsl = $rules->dsl_build(
        [
            {
                "attributes" => {
                    "key"  => "statement.perl.for",
                    "text" => "FOR eval",
                    "data" => {
                        "varname" => "kk",
                        "code"    => "1..10",
                        "config"  => { "varname" => "x", "code" => "()" }
                    },
                },
                "children" => [
                    {
                        "attributes" => {
                            'name'                => '',
                            'text'                => '',
                            'disabled'            => 0,
                            'semaphore_key'       => 'test-sem',
                            'trap_timeout_action' => 'abort',
                            'parallel_mode'       => 'fork',
                            'active'              => 1,
                            'trap_rollback'       => 1,
                            'error_trap'          => 'none',
                            'needs_rollback_mode' => 'none',
                            'run_forward'         => 1,
                            "data"                => {
                                'stdin'          => '',
                                'output_capture' => [],
                                'errors'         => 'fail',
                                'rc_warn'        => '',
                                'args'           => [],
                                'path'           => 'ls',
                                'output_error'   => [],
                                'output_ok'      => [],
                                'environment'    => {},
                                'rc_ok'          => '',
                                'rc_error'       => '',
                                'output_files'   => [],
                                'output_warn'    => [],
                                'home'           => '',
                            },
                            "key" => "service.test.op",
                        }
                    }
                ]
            },
            {
                attributes => {
                    key      => "statement.parallel.wait",
                    active   => 1,
                    name     => "WAIT for children",
                    data_key => 'foo',
                    data     => {
                        parallel_stash_keys => ['sem_cnt']
                    },
                },
                children => []
            }
        ]
    );

    my $package = 'test_sem_rule_' . int rand 9999;
    my $code    = eval sprintf q{
        package %s; use Baseliner::RuleFuncs; use Baseliner::Utils 'parse_vars';
        my $stash = {}; sub { %s; $stash } }, $package, $dsl;

    my $stash = $code->();

    is scalar( @{ $stash->{foo} } ), 10;
    is $_->{sem_cnt}, 1 for @{ $stash->{foo} };
};

subtest 'statement.retry: rethrows last error' => sub {
    _setup();

    my $statement = TestUtils->registry->registrar->{'statement.retry'};

    my $dsl = $statement->{param}->{dsl};

    local $ENV{attempts};

    my $code = $dsl->(
        Baseliner::Model::Rules->new,
        {
            children => [
                {
                    "attributes" => {
                        "key"  => "statement.perl.code",
                        "data" => {
                            "code" => qq{die "error=" . \$ENV{attempts}++}
                        },
                    }
                }
            ],
            data => { attempts => 3 }
        }
    );

    $code = sprintf q/package %s; my $stash = {}; sub current_task {} sub { %s }/, 'TestRetry' . int( rand(1000) ),
      $code;

    $code = eval $code;

    like exception { $code->() }, qr/error=2/;
};

subtest 'meta key with attributes sent to service op' => sub {
    TestUtils->cleanup_cis();
    mdb->rule->drop;

    Baseliner::Core::Registry->add_class( undef, 'event'   => 'BaselinerX::Type::Event' );
    Baseliner::Core::Registry->add_class( undef, 'service' => 'BaselinerX::Type::Service' );
    {

        package DummyPKGMetaKey;
        sub new { }
    };
    Baseliner::Core::Registry->add(
        'DummyPKGMetaKey',
        'service.test.op' => {
            name        => 'Test Op',
            icon        => '',
            form        => '/forms/tar_local.js',
            job_service => 1,
            handler     => sub {
                my ( $self, $c, $config ) = @_;
                my $stash = $c->stash;
                $stash->{is_ok} = exists $config->{meta};
            }
        }
    );

    my $id_rule = mdb->seq('id');
    mdb->rule->insert(
        {
            id        => "$id_rule",
            ts        => '2015-08-06 09:44:30',
            rule_type => "independent",
            rule_seq  => $id_rule,
            rule_tree => JSON::encode_json(
                [
                    {
                        "attributes" => {
                            'icon'                => '/static/images/icons/service-scripting-local.svg',
                            'palette'             => 0,
                            'disabled'            => 0,
                            'who'                 => 'root',
                            'timeout'             => '',
                            'text'                => 'Find *.c',
                            'expanded'            => 1,
                            'semaphore_key'       => '',
                            'id'                  => 'xnode-2995',
                            'ts'                  => '2014-12-06T11:49:36',
                            'trap_timeout_action' => 'abort',
                            'parallel_mode'       => 'none',
                            'name'                => 'Run a local script',
                            'active'              => 1,
                            'trap_rollback'       => 1,
                            'error_trap'          => 'none',
                            'needs_rollback_mode' => 'none',
                            'note'                => '',
                            'run_rollback'        => 1,
                            'data_key'            => 'find_c_files',
                            'trap_timeout'        => 0,
                            'run_forward'         => 1,
                            "data"                => {
                                'stdin'          => '',
                                'output_capture' => [],
                                'errors'         => 'fail',
                                'rc_warn'        => '',
                                'args'           => [],
                                'path'           => 'ls',
                                'output_error'   => [],
                                'output_ok'      => [],
                                'environment'    => {},
                                'rc_ok'          => '',
                                'rc_error'       => '',
                                'output_files'   => [],
                                'output_warn'    => [],
                                'home'           => '',
                            },
                            "key" => "service.test.op",
                        }
                    }
                ]
            )
        }
    );
    my $rules = _build_model();
    $rules->compile_rules();

    my $stash = { abc => 11 };

    my $rule_runner = Baseliner::RuleRunner->new;
    $rule_runner->find_and_run_rule(id_rule => $id_rule, stash => $stash);

    ok $stash->{is_ok};
};

subtest 'delete_rule: actually deletes the rule' => sub {
    _setup();

    my $id_rule = _create_rule();

    my $rules = _build_model();

    $rules->delete_rule( id_rule => $id_rule, username => 'john_doe' );

    my $rule = mdb->rule->find_one( { id => $id_rule } );

    ok !$rule;
};

subtest 'delete_rule: creates a delete version' => sub {
    _setup();

    my $id_rule = _create_rule();

    my $rules = _build_model();

    $rules->delete_rule( id_rule => $id_rule, username => 'john_doe' );

    my $version = mdb->rule_version->find_one( { id => $id_rule, deleted => '1' } );

    ok $version;
};

subtest 'delete_rule: creates the correct event' => sub {
    _setup();

    my $id_rule = _create_rule();

    my $rules = _build_model();

    $rules->delete_rule( id_rule => $id_rule, username => 'john_doe' );

    my @events = mdb->event->find( { event_key => 'event.rule.delete' } )->all;

    is scalar @events, 1;
};

subtest 'save_rule: actually creates a new rule' => sub {
    _setup();

    my $rules = _build_model();

    my $data = {
        rule_active       => '1',
        rule_name         => 'Test rule',
        rule_when         => 'post-offline',
        rule_event        => undef,
        rule_type         => 'independent',
        rule_compile_mode => 'none',
        rule_desc         => 'Test rule',
        ts                => mdb->ts,
        username          => 'john_doe'
    };

    $rules->save_rule(%$data);

    my @rules = mdb->rule->find( {} )->all;

    is scalar @rules, 1;
};

subtest 'save_rule: returns the rule id' => sub {
    _setup();

    my $rules = _build_model();

    my $data = {
        rule_active => '1',
        rule_name  => 'Test rule',
        rule_when  => 'post-offline',
        rule_event => undef,
        rule_type  => 'independent',
        rule_compile_mode  => 'none',
        rule_desc  => 'Test rule',
        ts =>  mdb->ts,
        username => 'john_doe'
    };

    my $ret = $rules->save_rule( %$data );

    is( mdb->rule->find({ id=>$ret->{id_rule} })->count, 1 );
};

subtest 'save_rule: data is correct' => sub {
    _setup();

    my $rules = _build_model();

    my $data = {
        rule_active => '1',
        rule_name  => 'Test rule',
        rule_when  => 'post-offline',
        rule_event => undef,
        rule_type  => 'independent',
        rule_compile_mode  => 'none',
        rule_desc  => 'Test rule',
        ts =>  mdb->ts,
        username => 'john_doe',
    };

    my $ret = $rules->save_rule( %$data );

    is_deeply(
        mdb->rule->find_one(
            { id => $ret->{id_rule} },
            {
                _id      => 0,
                wsdl     => 0,
                authtype => 0,
                id       => 0,
                rule_seq => 0,
                subtype  => 0
            }
        ),
        $data
    );
};

subtest 'save_rule: saves the tree' => sub {
    _setup();

    my $rules = _build_model();

    my $data = {
        rule_active => '1',
        rule_name  => 'Test rule',
        rule_when  => 'post-offline',
        rule_event => undef,
        rule_type  => 'independent',
        rule_compile_mode  => 'none',
        rule_desc  => 'Test rule',
        ts =>  mdb->ts,
        username => 'john_doe',
        rule_tree => [
            {
                "attributes"=> {
                    "icon"=> "/static/images/icons/statement-code-server.svg",
                    "key"=> "statement.code.server",
                    "text"=> "Server CODE",
                    "id"=> "rule-ext-gen38276-1456842988061",
                    "name"=> "Server CODE",
                    "data"=> {
                        "lang"=> "js",
                        "code"=> q{
                            var req = Cla.ws.request();
                            var res = Cla.ws.response();
                            res.data('hola', req.headers('accept-language'));
                            res.content_type('baz');
                        }
                    },
                },
                "children"=> [],
            }
        ]
    };

    my $ret = $rules->save_rule( %$data );
    my $tree = mdb->rule->find_one({ id=>$ret->{id_rule} })->{rule_tree};

    is_deeply( Util->_decode_json($tree), $data->{rule_tree} );
};

subtest 'save_rule: updates the rule data' => sub {
    _setup();

    my $rules = _build_model();

    my $data = {
        rule_active       => '1',
        rule_name         => 'Test rule',
        rule_when         => 'post-offline',
        rule_event        => undef,
        rule_type         => 'independent',
        rule_compile_mode => 'none',
        rule_desc         => 'Test rule',
        ts                => mdb->ts,
        username          => 'john_doe'
    };

    $rules->save_rule(%$data);

    my $rule = mdb->rule->find_one( { rule_name => 'Test rule' } );

    $data = {
        rule_id           => $rule->{id},
        rule_active       => '1',
        rule_name         => 'Test rule updated',
        rule_when         => 'post-offline',
        rule_event        => undef,
        rule_type         => 'independent',
        rule_compile_mode => 'none',
        rule_desc         => 'Test rule updated',
        ts                => mdb->ts,
        username          => 'mary_key'
    };

    $rules->save_rule(%$data);

    $rule = mdb->rule->find_one( { id => $rule->{id} } );

    is $rule->{rule_desc}, 'Test rule updated';
    is $rule->{username},  'mary_key';
};

subtest 'save_rule: creates the correct event when updated' => sub {
    _setup();

    my $rules = _build_model();

    my $data = {
        rule_active       => '1',
        rule_name         => 'Test rule',
        rule_when         => 'post-offline',
        rule_event        => undef,
        rule_type         => 'independent',
        rule_compile_mode => 'none',
        rule_desc         => 'Test rule',
        ts                => mdb->ts,
        username          => 'john_doe'
    };

    $rules->save_rule(%$data);

    my $rule = mdb->rule->find_one( { rule_name => 'Test rule' } );

    $data = {
        rule_id           => $rule->{id},
        rule_active       => '1',
        rule_name         => 'Test rule updated',
        rule_when         => 'post-offline',
        rule_event        => undef,
        rule_type         => 'independent',
        rule_compile_mode => 'none',
        rule_desc         => 'Test rule updated',
        ts                => mdb->ts,
        username          => 'mary_key'
    };

    $rules->save_rule(%$data);

    my @events = mdb->event->find( { event_key => 'event.rule.update' } )->all;

    is scalar @events, 1;
};

subtest 'save_rule: creates the correct event for new rule' => sub {
    _setup();

    my $rules = _build_model();

    my $data = {
        rule_active       => '1',
        rule_name         => 'Test rule',
        rule_when         => 'post-offline',
        rule_event        => undef,
        rule_type         => 'independent',
        rule_compile_mode => 'none',
        rule_desc         => 'Test rule',
        ts                => mdb->ts,
        username          => 'john_doe'
    };

    $rules->save_rule(%$data);

    my @events = mdb->event->find( { event_key => 'event.rule.create' } )->all;

    is scalar @events, 1;
};

subtest 'restore_rule: actually restores the rule' => sub {
    _setup();

    my $id_rule = _create_rule();

    my $rules = _build_model();

    $rules->delete_rule( id_rule => $id_rule, username => 'john_doe' );

    $rules->restore_rule( id_rule => $id_rule );
    my $rule = mdb->rule->find_one( { id => $id_rule } );

    ok $rule;
};

subtest 'dsl_build: builds empty dsl' => sub {
    _setup();

    my $rules = _build_model();

    my $dsl = $rules->dsl_build;

    is $dsl, '';
};

subtest 'dsl_build: builds dsl' => sub {
    _setup();

    my $rules = _build_model();

    my $dsl = $rules->dsl_build(
        {
            "attributes" => {
                "palette"        => 0,
                "disabled"       => 0,
                "on_drop_js"     => undef,
                "key"            => "statement.code.server",
                "who"            => "root",
                "text"           => "Server CODE",
                "expanded"       => 1,
                "run_sub"        => 1,
                "leaf"           => 1,
                "active"         => 1,
                "name"           => "Server CODE",
                "holds_children" => 0,
                "data"           => { "lang" => "perl", "code" => "foo();" },
                "nested"         => "0",
                "on_drop"        => ""
            },
            "children" => []
        }
    );

    is $dsl, <<'EOF';
# task: Server CODE

current_task( $stash, id_rule => q{}, rule_name => q{}, name => q{Server CODE}, level => 0 );

foo();

EOF
};

subtest 'dsl_build: builds dsl with correct nested level' => sub {
    _setup();

    my $rules = _build_model();

    my $dsl = $rules->dsl_build(
        {
            "attributes" => {
                "palette"        => 0,
                "disabled"       => 0,
                "on_drop_js"     => undef,
                "key"            => "statement.if.var",
                "text"           => "IF var THEN",
                "expanded"       => 1,
                "run_sub"        => 1,
                "leaf"           => 0,
                "name"           => "IF var THEN",
                "active"         => 1,
                "holds_children" => 1,
                "data"           => { variable => 'foo', value => 'bar' },
                "nested"         => "0",
                "on_drop"        => ""
            },
            "children" => [
                {
                    "attributes" => {
                        "palette"        => 0,
                        "disabled"       => 0,
                        "on_drop_js"     => undef,
                        "key"            => "statement.code.server",
                        "text"           => "INSIDE IF",
                        "expanded"       => 1,
                        "run_sub"        => 1,
                        "leaf"           => 1,
                        "name"           => "Server CODE",
                        "active"         => 1,
                        "holds_children" => 0,
                        "data"           => {},
                        "nested"         => "0",
                        "on_drop"        => ""
                    },
                    "children" => []
                }
            ]
        }
    );

    is $dsl, <<'EOF';
# task: IF var THEN

current_task( $stash, id_rule => q{}, rule_name => q{}, name => q{IF var THEN}, level => 0 );

if ( $stash->{'foo'} eq 'bar' ) {

    # task: INSIDE IF

    current_task( $stash, id_rule => q{}, rule_name => q{}, name => q{INSIDE IF}, level => 1 );

}

EOF
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

    my $id_rule = _create_rule();

    $rule_tree->[0]->{attributes}->{text} = 'CHECK2';
    Baseliner::Model::Rules->new->write_rule(
        id_rule    => $id_rule,
        username   => 'newuser',
        stmts_json => JSON::encode_json($rule_tree)
    );

    my $version_id = mdb->rule_version->find_one->{_id} . '';

    my $model = _build_model();

    $model->tag_version( version_id => $version_id, version_tag => 'production' );

    my $rule_version = mdb->rule_version->find_one( { _id => mdb->oid($version_id) } );

    is $rule_version->{version_tag}, 'production';
};

subtest 'tag_version: throws when unknown version' => sub {
    _setup();

    my $model = _build_model();

    like exception { $model->tag_version( version_id => 'unknown', version_tag => 'production' ) },
      qr/Version not found: unknown/;
};

subtest 'tag_version: throws when tag already exists' => sub {
    _setup();

    my $id_rule = _create_rule();

    Baseliner::Model::Rules->new->write_rule(
        id_rule  => $id_rule,
        username => 'newuser',
    );

    my $version_id =
      mdb->rule_version->find->sort( { ts => 1 } )->next->{_id} . '';

    my $model = _build_model();
    $model->tag_version( version_id => $version_id, version_tag => 'tag' );

    Baseliner::Model::Rules->new->write_rule(
        id_rule  => $id_rule,
        username => 'newuser',
    );

    $version_id =
      mdb->rule_version->find( { _id => { '$ne' => mdb->oid($version_id) } } )->sort( { ts => 1 } )->next->{_id} . '';

    like exception { $model->tag_version( version_id => $version_id, version_tag => 'tag' ) },
      qr/Version tag already exists/;
};

subtest 'tag_version: does not throw when saving same tag with same version' => sub {
    _setup();

    my $id_rule = _create_rule();

    Baseliner::Model::Rules->new->write_rule(
        id_rule  => $id_rule,
        username => 'newuser',
    );

    my $version_id = mdb->rule_version->find->sort( { ts => 1 } )->next->{_id} . '';

    my $model = _build_model();

    $model->tag_version( version_id => $version_id, version_tag => 'tag' );

    ok $model->tag_version( version_id => $version_id, version_tag => 'tag' );
};

subtest 'untag_version: untags version' => sub {
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

    my $id_rule = _create_rule();

    $rule_tree->[0]->{attributes}->{text} = 'CHECK2';
    Baseliner::Model::Rules->new->write_rule(
        id_rule    => $id_rule,
        username   => 'newuser',
        stmts_json => JSON::encode_json($rule_tree)
    );

    my $version_id = mdb->rule_version->find_one->{_id} . '';

    my $model = _build_model();

    $model->tag_version( version_id => $version_id, version_tag => 'production' );

    $model->untag_version( version_id => $version_id);

    my $rule_version = mdb->rule_version->find_one( { _id => mdb->oid($version_id) } );

    ok !exists $rule_version->{version_tag};
};

subtest 'list_versions: returns rule versions' => sub {
    _setup();

    my $id_rule = _create_rule();

    mock_time '2015-01-01' => sub {
        Baseliner::Model::Rules->new->write_rule(
            id_rule  => $id_rule,
            username => 'newuser',
        );
    };

    mock_time '2015-01-02' => sub {
        Baseliner::Model::Rules->new->write_rule(
            id_rule  => $id_rule,
            username => 'anotheruser',
        );
    };

    my $model = _build_model();

    my @versions = $model->list_versions($id_rule);

    is scalar @versions, 2;
    is $versions[0]->{username}, 'anotheruser';
    is $versions[1]->{username}, 'newuser';
};

subtest 'list_versions: returns rule versions only with tags' => sub {
    _setup();

    my $id_rule = _create_rule();

    mock_time '2015-01-01' => sub {
        Baseliner::Model::Rules->new->write_rule(
            id_rule  => $id_rule,
            username => 'newuser',
        );
    };

    mock_time '2015-01-02' => sub {
        Baseliner::Model::Rules->new->write_rule(
            id_rule  => $id_rule,
            username => 'anotheruser',
        );
    };

    my $model = _build_model();

    my @versions = $model->list_versions($id_rule);
    $model->tag_version( version_id => $versions[0]->{_id}, version_tag => 'production' );

    @versions = $model->list_versions($id_rule, only_tags => 1);

    is scalar @versions, 1;
    is $versions[0]->{username}, 'anotheruser';
};

subtest 'resolve_rule: loads rule by id' => sub {
    _setup();

    my $id_rule = _create_rule();

    my $model = _build_model();

    my $rule = $model->resolve_rule(id_rule => $id_rule);

    ok $rule;
};

subtest 'resolve_rule: loads rule by name' => sub {
    _setup();

    _create_rule();

    my $model = _build_model();

    my $rule = $model->resolve_rule(id_rule => 'test');

    ok $rule;
};

subtest 'resolve_rule: throws when cannot load by id' => sub {
    _setup();

    my $model = _build_model();

    like exception { $model->resolve_rule(id_rule => 'unknown') }, qr/Rule with id or name `unknown` not found/;
};

subtest 'resolve_rule: loads rule version id' => sub {
    _setup();

    my $id_rule = _create_rule();

    Baseliner::Model::Rules->new->write_rule(
        id_rule  => $id_rule,
        username => 'anotheruser',
    );

    my $model = _build_model();

    my @versions = $model->list_versions($id_rule);

    my $rule = $model->resolve_rule( id_rule => $id_rule, version_id => '' . $versions[0]->{_id} );

    ok $rule;
};

subtest 'resolve_rule: throws when cannot load by version id' => sub {
    _setup();

    my $id_rule = _create_rule();

    my $model = _build_model();

    like exception { $model->resolve_rule(id_rule => $id_rule, version_id => '123') }, qr/Version `123` of rule `$id_rule` not found/;
};

subtest 'resolve_rule: loads rule version tag' => sub {
    _setup();

    my $id_rule = _create_rule();

    Baseliner::Model::Rules->new->write_rule(
        id_rule  => $id_rule,
        username => 'anotheruser',
    );

    my $model = _build_model();

    my @versions = $model->list_versions($id_rule);
    $model->tag_version( version_id => $versions[0]->{_id}, version_tag => 'production' );

    my $rule = $model->resolve_rule( id_rule => $id_rule, version_tag => 'production' );

    ok $rule;
};

subtest 'resolve_rule: throws when cannot load by version tag' => sub {
    _setup();

    my $rule_id = _create_rule();

    my $model = _build_model();

    like exception { $model->resolve_rule( id_rule => $rule_id, version_tag => '123' ) },
      qr/Version tag `123` of rule `$rule_id` not found/;
};

subtest 'compile_wsdl: returns the wsdl compiled' => sub {
    _setup();

    my $model            = _build_model();
    my $target_namespace = "url";
    my $wsdl             = qq'<definitions name="HelloService"
   targetNamespace= "$target_namespace"
   xmlns="http://schemas.xmlsoap.org/wsdl/">
   <service name="Hello_Service">
   </service>
   </definitions>';

    my $output = $model->compile_wsdl($wsdl);

    is $output->{index}->{service}->{"{$target_namespace}Hello_Service"}->{name}, 'Hello_Service';
};

subtest 'compile_wsdl: throws an error if wsdl has incorrect format' => sub {
    _setup();

    my $model = _build_model();
    my $wsdl  = 'foo';
    like exception {
        capture {
            my $output = $model->compile_wsdl($wsdl);
        }
    }, qr/Error compiling WSDL:<br \/><pre>error: don't known how to interpret XML data/;
};

subtest 'init_report_tasks: fails if not rule name is sent' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule( rule_type => "report" );
    my $rule = mdb->rule->find_one( { id => $id_rule } );
    my $model = _build_model();

    like exception {
        $model->init_report_tasks();
    }, qr/Rule not found/;
};

subtest 'init_report_tasks: fails if not rule owner is sent' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule(
        rule_type => "report",
        rule_name => 'My Rule'
    );
    my $rule = mdb->rule->find_one( { id => $id_rule } );
    my $model = _build_model();

    like exception {
        $model->init_report_tasks( $rule->{rule_name} );
    }, qr/User not found/;
};

subtest 'init_report_tasks: security code returns 1 when user is the owner' => sub {
    _setup();

    my $rule_owner = "Owner";
    my $rule_name  = "My Rule";
    my $id_rule    = TestSetup->create_rule(
        rule_type => "report",
        rule_name => $rule_name,
        username  => $rule_owner
    );
    my $rule = mdb->rule->find_one( { id => $id_rule } );
    my $model = _build_model();
    my @tree
        = $model->init_report_tasks( $rule->{rule_name}, $rule->{username} );
    my $code1 = eval 'my $stash = {};' . $tree[0]->{data}{code};

    ok( $code1->( username => $rule_owner ) );
};

subtest 'init_report_tasks: security code returns 0 when user is not the owner' => sub {
    _setup();

    my $rule_owner = "Owner";
    my $rule_name  = "My Rule";
    my $id_rule    = TestSetup->create_rule(
        rule_type => "report",
        rule_name => $rule_name,
        username  => $rule_owner
    );
    my $rule = mdb->rule->find_one( { id => $id_rule } );
    my $model = _build_model();
    my @tree = $model->init_report_tasks( $rule->{rule_name}, $rule->{username} );
    my $code = eval 'my $stash = {};' . $tree[0]->{data}{code};

    ok( !$code->( username => "Other User" ) );
};

subtest 'init_report_tasks: returns correct codes when rule is a report with a correct rule name and correct owner' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule(
        rule_type => "report",
        rule_name => 'My Rule',
        username  => "Owner"
    );
    my $rule = mdb->rule->find_one( { id => $id_rule } );
    my $model = _build_model();
    my @tree = $model->init_report_tasks( $rule->{rule_name}, $rule->{username} );

    is $tree[0]->{key}, 'statement.perl.code';
    ok( eval $tree[0]->{data}{code} =~ qr/Owner/ );
    ok( eval $tree[1]->{data}{code} =~ qr/My Rule/ );
    is scalar @tree, 3;
};

subtest 'build_tree: returns fieldlets by default when rule is a form' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule( rule_type => "form", );
    my $model   = _build_model();
    my @tree    = $model->build_tree($id_rule);

    is $tree[0]->{data}->{fieldletType}, 'fieldlet.system.status_new';
    is $tree[1]->{data}->{fieldletType}, 'fieldlet.system.title';
};

subtest 'build_tree: returns correct codes when rule is a report' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule(
        rule_type => "report",
        rule_name => "My Rule",
        username  => "My User"
    );
    my $model = _build_model();
    my @tree  = $model->build_tree($id_rule);

    is $tree[0]->{key}, 'statement.perl.code';
    is scalar @tree, 3;
};

subtest 'build_tree: returns steps when rule is a pipeline' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule( rule_type => "pipeline" );
    my $model   = _build_model();
    my @tree    = $model->build_tree($id_rule);

    is scalar @tree, 5;
    is $tree[0]->{text}, 'CHECK';
    is $tree[1]->{text}, 'INIT';
    is $tree[2]->{text}, 'PRE';
    is $tree[3]->{text}, 'RUN';
    is $tree[4]->{text}, 'POST';
};

subtest 'save_rule: data is correct' => sub {
    _setup();

    my $rules = _build_model();

    my $data = {
        rule_active => '1',
        rule_name  => 'Test rule',
        rule_when  => 'post-offline',
        rule_event => undef,
        rule_type  => 'independent',
        rule_compile_mode  => 'none',
        rule_desc  => 'Test rule',
        ts =>  mdb->ts,
        username => 'john_doe',
    };

    my $ret = $rules->save_rule( %$data );

    is_deeply(
        mdb->rule->find_one(
            { id => $ret->{id_rule} },
            {
                _id      => 0,
                wsdl     => 0,
                authtype => 0,
                id       => 0,
                rule_seq => 0,
                subtype  => 0
            }
        ),
        $data
    );
};

subtest 'get_rules_info: returns nothing when user has no permissions' => sub {
    _setup();

    my $model = _build_model();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user(project => $project, id_role => $id_role);

    my (@rows) = $model->get_rules_info({username => $user->username});

    is @rows, 0;
};

subtest 'get_rules_info: returns all rules when permissions without bounds' => sub {
    _setup();

    TestSetup->create_rule();

    my $model = _build_model();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role(actions => [{action => 'action.admin.rules', bounds => [{}]}]);
    my $user = TestSetup->create_user(project => $project, id_role => $id_role);

    my (@rows) = $model->get_rules_info({username => $user->username});

    is @rows, 1;
};

subtest 'get_rules_info: returns only allowed rules' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule();
    my $id_rule2 = TestSetup->create_rule();

    my $model = _build_model();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role(actions => [{action => 'action.admin.rules', bounds => [{id_rule => $id_rule}]}]);
    my $user = TestSetup->create_user(project => $project, id_role => $id_role);

    my (@rows) = $model->get_rules_info({username => $user->username});

    is @rows, 1;
    is $rows[0]->{id}, $id_rule;
};

subtest 'get_rule_tree: fails if rule_id missing' => sub {
    _setup();

    my $model = _build_model();

    like exception { $model->get_rule_tree() }, qr/Missing id_rule/;
};

subtest 'get_rule_tree: fails if rule is not found' => sub {
    _setup();

    my $model = _build_model();

    like exception { $model->get_rule_tree("123") }, qr/Rule 123 not found/;
};

subtest 'get_rule_tree: returns rule_tree' => sub {
    _setup();

    my $code    = "return 'hi there'";
    my $iso_ts  = '2016-01-01T00:00:00';
    my $id_rule = _create_rule( code => $code, ts => $iso_ts );

    my $model = _build_model();

    my $rule_tree = $model->get_rule_tree($id_rule);

    like $rule_tree, qr/return 'hi there'/;
};

subtest 'is_rule_active: returns boolean with rule status' => sub {
    _setup();

    my $id_rule_active = _create_rule( id => 1 );
    my $model = _build_model();

    ok $model->is_rule_active( id_rule => $id_rule_active );
};

subtest 'dsl_build: builds if var condition dsl' => sub {
    _setup();

    my $rules = _build_model();

    my $dsl = $rules->dsl_build(
        {
            "attributes" => {
                "key"      => "statement.if.var_condition",
                "text"     => "IF",
                "data"     => {
                    'when' => 'any',

                    "operand_a[0]"           => "foo",
                    "operand_b[0]"           => "bar",
                    "operator[0]"            => "eq",
                    "options[0].ignore_case" => "on",

                    "operand_a[1]"           => "foo",
                    "operand_b[1]"           => "",
                    "operator[1]"            => "is_empty",
                }
            },
            "children" => [
                {
                    "attributes" => {
                        "key"      => "statement.perl.code",
                        "text"     => "CODE",
                        "data"     => {
                            code => 'return 1'
                        }
                    },
                }
            ]
        }
    );

    my $package = 'test_statement_call_' . int( rand(1000) );

    my $code = sprintf q/package %s; use Baseliner::RuleFuncs; use Baseliner::Utils 'parse_vars'; sub { my $stash = shift; %s }/,
      $package, $dsl;

    $code = eval $code;

    ok $code->( {} );
    ok $code->( { foo => 'bar' } );
};

subtest 'dsl_build: builds while condition dsl' => sub {
    _setup();

    my $rules = _build_model();

    my $dsl = $rules->dsl_build(
        {
            "attributes" => {
                "key"  => "statement.while",
                "text" => "WHILE",
                "data" => {
                    'when' => 'any',

                    "operand_a[0]"       => "foo",
                    "operand_b[0]"       => "10",
                    "operator[0]"        => "lt",
                    "options[0].numeric" => "on",
                }
            },
            "children" => [
                {
                    "attributes" => {
                        "key"  => "statement.perl.code",
                        "text" => "CODE",
                        "data" => {
                            code => '$stash->{foo}++;'
                        }
                    },
                }
            ]
        }
    );

    my $package = 'test_statement_call_' . int( rand(1000) );

    my $code =
      sprintf q/package %s; use Baseliner::RuleFuncs; use Baseliner::Utils 'parse_vars'; sub { my $stash = shift; %s }/,
      $package, $dsl;

    $code = eval $code;

    my $stash = { foo => 0 };
    $code->($stash);

    is $stash->{foo}, 10;
};

subtest 'dsl_build: builds doe while condition dsl' => sub {
    _setup();

    my $rules = _build_model();

    my $dsl = $rules->dsl_build(
        {
            "attributes" => {
                "key"  => "statement.do_while",
                "text" => "WHILE",
                "data" => {
                    'when' => 'any',

                    "operand_a[0]"       => "foo",
                    "operand_b[0]"       => "10",
                    "operator[0]"        => "lt",
                    "options[0].numeric" => "on",
                }
            },
            "children" => [
                {
                    "attributes" => {
                        "key"  => "statement.perl.code",
                        "text" => "CODE",
                        "data" => {
                            code => '$stash->{foo}++;'
                        }
                    },
                }
            ]
        }
    );

    my $package = 'test_statement_call_' . int( rand(1000) );

    my $code =
      sprintf q/package %s; use Baseliner::RuleFuncs; use Baseliner::Utils 'parse_vars'; sub { my $stash = shift; %s }/,
      $package, $dsl;

    $code = eval $code;

    my $stash = { foo => 10 };
    $code->($stash);

    is $stash->{foo}, 11;
};

subtest 'statement.var.push: pushes vars' => sub {
    _setup();

    my $rules = _build_model();

    my $dsl = $rules->dsl_build(
        {
            "attributes" => {
                "key"  => 'statement.var.push',
                "data" => {
                    variable => 'foo',
                    value    => 'bar',
                    uniq     => 0
                }
            }
        }
    );

    my $package = 'test_statement_call_' . int( rand(1000) );

    my $code =
      sprintf q/package %s; use Baseliner::RuleFuncs; use Baseliner::Utils qw{parse_vars _unique _array}; /
      . q/sub { my $stash = shift; %s; return $stash }/,
      $package, $dsl;

    $code = eval $code;

    is_deeply $code->()->{foo}, ['bar'];
    is_deeply $code->( { foo => undef } )->{foo}, ['bar'];
    is_deeply $code->( { foo => '123' } )->{foo}, ['123', 'bar'];
    is_deeply $code->( { foo => ['123'] } )->{foo}, [ '123', 'bar' ];
    is_deeply $code->( { foo => ['bar'] } )->{foo}, [ 'bar', 'bar' ];
};

subtest 'statement.var.push: pushes vars uniquely' => sub {
    _setup();

    my $rules = _build_model();

    my $dsl = $rules->dsl_build(
        {
            "attributes" => {
                "key"  => 'statement.var.push',
                "data" => {
                    variable => 'foo',
                    value    => 'bar',
                    uniq     => 1
                }
            }
        }
    );

    my $package = 'test_statement_call_' . int( rand(1000) );

    my $code =
      sprintf q/package %s; use Baseliner::RuleFuncs; use Baseliner::Utils qw{parse_vars _unique _array}; /
      . q/sub { my $stash = shift; %s; return $stash }/,
      $package, $dsl;

    $code = eval $code;

    is_deeply $code->( { foo => ['bar'] } )->{foo}, ['bar'];
};

subtest 'statement.var.push: pushes vars flattening then first' => sub {
    _setup();

    my $rules = _build_model();

    my $dsl = $rules->dsl_build(
        {
            "attributes" => {
                "key"  => 'statement.var.push',
                "data" => {
                    variable => 'foo',
                    value    => ['bar'],
                    flatten  => 1
                }
            }
        }
    );

    my $package = 'test_statement_call_' . int( rand(1000) );

    my $code =
      sprintf q/package %s; use Baseliner::RuleFuncs; use Baseliner::Utils qw{parse_vars _unique _array}; /
      . q/sub { my $stash = shift; %s; return $stash }/,
      $package, $dsl;

    $code = eval $code;

    is_deeply $code->( { foo => ['bar'] } )->{foo}, ['bar'];
};

subtest 'statement.if.any_bl: checks if current bl' => sub {
    _setup();

    my $rules = _build_model();

    my $dsl = $rules->dsl_build(
        {
            "attributes" => {
                "key"  => 'statement.if.any_bl',
                "data" => {
                    bls => 'TEST'
                }
            },
            children => [
                {
                    "attributes" => {
                        "key"  => "statement.perl.code",
                        "data" => {
                            "code" => q{$stash->{ok} = 1}
                        },
                    }
                }
            ],
        }
    );

    my $package = 'test_statement_call_' . int( rand(1000) );

    my $code =
      sprintf q/package %s; use Baseliner::RuleFuncs; use Baseliner::Utils qw{parse_vars _array _any}; /
      . q/sub { my $stash = shift; %s; return $stash }/,
      $package, $dsl;

    $code = eval $code;

    ok $code->( { bl => 'TEST' } )->{ok};
    ok !$code->( { bl => 'QA' } )->{ok};
};

subtest 'statement.if.any_bl: checks if current bl from multiple bls' => sub {
    _setup();

    my $rules = _build_model();

    my $dsl = $rules->dsl_build(
        {
            "attributes" => {
                "key"  => 'statement.if.any_bl',
                "data" => {
                    bls => [ 'TEST', 'QA' ]
                }
            },
            children => [
                {
                    "attributes" => {
                        "key"  => "statement.perl.code",
                        "data" => {
                            "code" => q{$stash->{ok} = 1}
                        },
                    }
                }
            ],
        }
    );

    my $package = 'test_statement_call_' . int( rand(1000) );

    my $code =
      sprintf q/package %s; use Baseliner::RuleFuncs; use Baseliner::Utils qw{parse_vars _array _any}; /
      . q/sub { my $stash = shift; %s; return $stash }/,
      $package, $dsl;

    $code = eval $code;

    ok $code->( { bl => 'TEST' } )->{ok};
    ok $code->( { bl => 'QA' } )->{ok};
    ok !$code->( { bl => 'PROD' } )->{ok};
};

subtest 'statement.if.any_bl: checks if current bl using mids' => sub {
    _setup();

    my $bl = TestUtils->create_ci('bl', bl => 'TEST');

    my $rules = _build_model();

    my $dsl = $rules->dsl_build(
        {
            "attributes" => {
                "key"  => 'statement.if.any_bl',
                "data" => {
                    bls => [ $bl->mid, 'QA' ]
                }
            },
            children => [
                {
                    "attributes" => {
                        "key"  => "statement.perl.code",
                        "data" => {
                            "code" => q{$stash->{ok} = 1}
                        },
                    }
                }
            ],
        }
    );

    my $package = 'test_statement_call_' . int( rand(1000) );

    my $code =
      sprintf q/package %s; use Baseliner::RuleFuncs; use Baseliner::Utils qw{parse_vars _array _any}; /
      . q/sub { my $stash = shift; %s; return $stash }/,
      $package, $dsl;

    $code = eval $code;

    ok $code->( { bl => 'TEST' } )->{ok};
    ok $code->( { bl => 'QA' } )->{ok};
    ok !$code->( { bl => 'PROD' } )->{ok};
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Statement',
        'BaselinerX::CI',
        'BaselinerX::Type::Menu',
        'BaselinerX::Type::Config',
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Service',
        'BaselinerX::Type::Statement',
        'BaselinerX::Type::Fieldlet',
        'BaselinerX::Fieldlets',
        'BaselinerX::Events',
        'Baseliner::Model::Rules',
        'Baseliner::Controller::Rule',
    );

    TestUtils->cleanup_cis;

    mdb->event->drop;
    mdb->rule->drop;
    mdb->rule_version->drop;
    mdb->index_all('sem');
}

sub _create_rule {
    my (%params) = @_;

    my $active = exists $params{active} ? $params{active} : "1";
    my $code = $params{code} || q%return 'hi there';%;
    my $ts   = $params{ts}   || '' . Class::Date->now();
    my $rule_id = $params{id} || '1';
    my $iso_ts = $ts;
    $iso_ts =~ s/\s/T/;

    mdb->rule->insert(
        {
            id                => $rule_id,
            "rule_active"     => $active,
            "wsdl"            => "",
            "rule_type"       => "chain",
            "rule_desc"       => "",
            "authtype"        => "required",
            "rule_name"       => "test",
            rule_compile_mode => $params{rule_compile_mode} // 'none',
            "ts"              => $ts,
            "username"        => "root",
            "rule_seq"        => 1,
            "rule_event"      => undef,
            "rule_when"       => "promote",
            "subtype"         => "-",
            "detected_errors" => "",
            "rule_tree" =>
qq%[{"attributes":{"text":"CHECK","icon":"/static/images/icons/job.svg","key":"statement.step","expanded":true,"leaf":false,"id":"xnode-1023"},"children":[]},{"attributes":{"key":"statement.step","expanded":true,"leaf":false,"icon":"/static/images/icons/job.svg","text":"INIT","id":"xnode-1024"},"children":[]},{"attributes":{"key":"statement.step","expanded":true,"leaf":false,"text":"PRE","icon":"/static/images/icons/job.svg","id":"xnode-1025"},"children":[]},{"attributes":{"icon":"/static/images/icons/job.svg","text":"RUN","leaf":false,"key":"statement.step","expanded":true,"id":"xnode-1026"},"children":[{"attributes":{"icon":"/static/images/icons/cog.svg","on_drop_js":null,"on_drop":"","leaf":true,"nested":0,"holds_children":false,"run_sub":true,"palette":false,"text":"CODE","key":"statement.perl.code","id":"rule-ext-gen1029-1435664566485","name":"CODE","data":{"code":"$code"},"ts":"$iso_ts","who":"root","expanded":false},"children":[]}]},{"attributes":{"leaf":false,"key":"statement.step","expanded":true,"text":"POST","icon":"/static/images/icons/job.svg","id":"xnode-1027"},"children":[]}]%
        }
    );

    return $rule_id;
}

sub _build_model {
    return Baseliner::Model::Rules->new();
}
