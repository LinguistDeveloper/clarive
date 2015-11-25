use strict;
use warnings;

use Test::More;

use lib 't/lib';
use TestEnv;
use TestUtils;

TestEnv->setup;

use Baseliner::Role::CI;
use BaselinerX::Type::Statement;
use BaselinerX::Type::Service;
use JSON ();

use_ok 'Baseliner::Model::Rules';

subtest 'does compile when config flag is conditional and rule is on' => sub {
    _setup( rule_compile_mode => 'precompile' );

    my $rules = _build_model();

    $rules->compile_rules( rule_precompile => 'depends' );

    my $cr = Baseliner::CompiledRule->new( id_rule => 1, @_ );
    ok $cr->package->can('meta');
    ok $cr->is_loaded;
    $cr->unload;
};

subtest 'does not compile when config flag is conditional and rule is off' => sub {
    _setup( rule_compile_mode => 'none' );

    my $rules = _build_model();

    $rules->compile_rules( rule_precompile => 'depends' );

    my $cr = Baseliner::CompiledRule->new( id_rule => 1, @_ );
    ok !$cr->package->can('meta');
};

subtest 'does compile when config flag is on and rule is off' => sub {
    _setup( rule_compile_mode => 'none' );

    my $rules = _build_model();

    $rules->compile_rules( rule_precompile => 'always' );

    my $cr = Baseliner::CompiledRule->new( id_rule => 1, @_ );
    ok $cr->package->can('meta');
    ok $cr->is_loaded;
    $cr->unload;
};

subtest 'does compile when config flag is on and rule is on' => sub {
    _setup( rule_compile_mode => 'precompile' );

    my $rules = _build_model();

    $rules->compile_rules( rule_precompile => 'always' );

    my $cr = Baseliner::CompiledRule->new( id_rule => 1, @_ );
    ok $cr->package->can('meta');
    ok $cr->is_loaded;
    $cr->unload;
};

subtest 'does not compile when config flag is off and rule is on' => sub {
    _setup( rule_compile_mode => 'precompile' );

    my $rules = _build_model();

    $rules->compile_rules( rule_precompile => 'none' );

    my $cr = Baseliner::CompiledRule->new( id_rule => 1, @_ );
    ok !$cr->package->can('meta');
};

subtest 'does not compile when config flag is off and rule is off' => sub {
    _setup( rule_compile_mode => 'none' );

    my $rules = _build_model();

    $rules->compile_rules( rule_precompile => 'none' );

    my $cr = Baseliner::CompiledRule->new( id_rule => 1, @_ );
    ok !$cr->package->can('meta');
};

subtest 'statement.call' => sub {
    TestUtils->setup_registry('Baseliner::Model::Rules');

    my $statement = TestUtils->registry->registrar->{'statement.call'};

    my $dsl = $statement->{param}->{dsl};

    my $code = $dsl->(undef, {id_rule => '123'});

    my $package = 'test_statement_call_' . int(rand(1000));

    $code = sprintf q/package %s; use Baseliner::Utils 'parse_vars'; my $stash = {}; sub call { \@_ } sub { %s }/,
      $package, $code;

    $code = eval $code;

    my $args = $code->();

    is $args->[0], '123';
};

subtest 'statement.call with parse_vars' => sub {
    TestUtils->setup_registry('Baseliner::Model::Rules');

    my $statement = TestUtils->registry->registrar->{'statement.call'};

    my $dsl = $statement->{param}->{dsl};

    my $code = $dsl->(undef, {id_rule => '${some_var}'});

    my $package = 'test_statement_call_' . int(rand(1000));

    $code = sprintf q/package %s; use Baseliner::Utils 'parse_vars'; my $stash = {some_var => 'hi!'}; sub call { \@_ } sub { %s }/,
      $package, $code;

    $code = eval $code;

    my $args = $code->();

    is $args->[0], 'hi!';
};

subtest 'statement.parallel.wait: saves result to data_key' => sub {
    TestUtils->setup_registry('Baseliner::Model::Rules');

    my $statement = TestUtils->registry->registrar->{'statement.parallel.wait'};

    my $dsl = $statement->{param}->{dsl};

    my $code = $dsl->(undef, {data_key => 'output'});

    my $package = 'test_statement_call_' . int(rand(1000));

    $code = sprintf q/package %s; my $stash = {}; sub wait_for_children { '123' } sub { %s; $stash }/,
      $package, $code;

    $code = eval $code;

    my $args = $code->();

    is_deeply $args, {output => '123'};
};

subtest 'meta key with attributes sent to service op' => sub {
    TestUtils->cleanup_cis();
    mdb->rule->drop;

    Baseliner::Core::Registry->add_class( undef, 'event'    => 'BaselinerX::Type::Event' );
    Baseliner::Core::Registry->add_class( undef, 'service' => 'BaselinerX::Type::Service' );
    { package DummyPKG; sub new { } };
    Baseliner::Core::Registry->add(
        'DummyPKG',
        'service.test.op' => {
            name => 'Test Op',
            icon => '',
            form => '/forms/tar_local.js',
            job_service => 1,
            handler => sub {
                my ($self, $c, $config ) = @_;
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
                            'icon'                => '/static/images/icons/script-local.png',
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
                            "data" => {
                                'stdin'          => '',
                                'output_capture' => [],
                                'errors'         => 'fail',
                                'rc_warn'        => '',
                                'args'           => [],
                                'path'           => 'ls',
                                'output_error'   => [],
                                'output_ok'      => [],
                                'environment'  => {},
                                'rc_ok'        => '',
                                'rc_error'     => '',
                                'output_files' => [],
                                'output_warn'  => [],
                                'home'         => '',
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
    my $cr = Baseliner::CompiledRule->new( id_rule => $id_rule, @_ );
    $cr->compile();
    my $stash = { abc=>11 };
    $cr->run(stash => $stash);
    ok $stash->{is_ok};
};

sub _setup {
    my (%params) = @_;

    TestUtils->setup_registry('BaselinerX::Type::Statement', 'Baseliner::Model::Rules');

    my $code = $params{code} || q%return 'hi there';%;

    mdb->rule->drop;
    mdb->rule->insert(
        {
            id                => '1',
            "rule_active"     => "1",
            "wsdl"            => "",
            "rule_type"       => "chain",
            "rule_desc"       => "",
            "authtype"        => "required",
            "rule_name"       => "test",
            rule_compile_mode => $params{rule_compile_mode} // 'none',
            "ts"              => "2015-06-30 13:44:11",
            "username"        => "root",
            "rule_seq"        => 1,
            "rule_event"      => undef,
            "rule_when"       => "promote",
            "subtype"         => "-",
            "detected_errors" => "",
            "rule_tree" =>
qq%[{"attributes":{"text":"CHECK","icon":"/static/images/icons/job.png","key":"statement.step","expanded":true,"leaf":false,"id":"xnode-1023"},"children":[]},{"attributes":{"key":"statement.step","expanded":true,"leaf":false,"icon":"/static/images/icons/job.png","text":"INIT","id":"xnode-1024"},"children":[]},{"attributes":{"key":"statement.step","expanded":true,"leaf":false,"text":"PRE","icon":"/static/images/icons/job.png","id":"xnode-1025"},"children":[]},{"attributes":{"icon":"/static/images/icons/job.png","text":"RUN","leaf":false,"key":"statement.step","expanded":true,"id":"xnode-1026"},"children":[{"attributes":{"icon":"/static/images/icons/cog.png","on_drop_js":null,"on_drop":"","leaf":true,"nested":0,"holds_children":false,"run_sub":true,"palette":false,"text":"CODE","key":"statement.perl.code","id":"rule-ext-gen1029-1435664566485","name":"CODE","data":{"code":"$code"},"ts":"2015-06-30T13:42:57","who":"root","expanded":false},"children":[]}]},{"attributes":{"leaf":false,"key":"statement.step","expanded":true,"text":"POST","icon":"/static/images/icons/job.png","id":"xnode-1027"},"children":[]}]%
        }
    );
}

sub _build_model {
    return Baseliner::Model::Rules->new();
}

done_testing;
