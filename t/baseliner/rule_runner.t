use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Deep;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;
use TestSetup;

use JSON ();

use_ok 'Baseliner::RuleRunner';

subtest 'run_single_rule: runs rule' => sub {
    _setup();

    my $id_rule = _create_rule();

    my $runner = _build_runner();

    my $ret = $runner->run_single_rule( id_rule => $id_rule );

    cmp_deeply $ret,
      {
        ret => {
            stash => ignore(),
            dsl   => 'Clarive::RULE_1',
        },
        dsl => ''
      };
};

subtest 'run_rules: runs rule when' => sub {
    _setup();

    _create_rule( rule_type => 'event', event => 'on.something' );

    my $runner = _build_runner();

    my $ret = $runner->run_rules( when => 'event', event => 'on.something' );

    cmp_deeply $ret,
      {
        'stash' => {
            'rules_exec' => {
                'on.something' => {
                    'event' => 0
                }
            }
        },
        'rule_log' => []
      };
};

subtest 'run_dsl: merges default vars' => sub {
    _setup();

    TestUtils->create_ci(
        'variable',
        name      => 'foo',
        var_type  => 'value',
        variables => { '*' => 'bar' }
    );

    my $dsl   = 'print $stash->{foo}';
    my $stash = {};

    my $runner = _build_runner();

    my $ret = $runner->run_dsl(dsl => $dsl, stash => $stash);

    is $ret->{output}, 'bar';
};

subtest 'run_dsl: default vars do not overwrite existing ones' => sub {
    _setup();

    TestUtils->create_ci(
        'variable',
        name      => 'foo',
        var_type  => 'value',
        variables => { '*' => 'bar' }
    );

    my $dsl   = 'print $stash->{foo}';
    my $stash = {foo => 'baz'};

    my $runner = _build_runner();

    my $ret = $runner->run_dsl(dsl => $dsl, stash => $stash);

    is $ret->{output}, 'baz';
};

done_testing;

sub _create_rule {
    my (%params) = @_;

    mdb->rule->insert(
        {
            id            => '1',
            "rule_active" => "1",
            "rule_type"   => "chain",
            "rule_desc"   => "",
            "rule_name"   => "test",
            "ts"          => '2016-01-01 00:00:00',
            "username"    => "root",
            "rule_seq"    => 1,
            "rule_when"   => "promote",
            "rule_tree"   => JSON::encode_json(
                [
                    {
                        "attributes" => {
                            "palette"        => 0,
                            "disabled"       => 0,
                            "on_drop_js"     => undef,
                            "key"            => "statement.code.server",
                            "who"            => "root",
                            "text"           => "Server CODE",
                            "expanded"       => \1,
                            "run_sub"        => 1,
                            "leaf"           => \1,
                            "active"         => 1,
                            "name"           => "Server CODE",
                            "holds_children" => 0,
                            "data"           => { "lang" => "perl", "code" => "print 'hello';" },
                            "nested"         => "0",
                            "on_drop"        => ""
                        },
                        "children" => []
                    }
                ]
            )
        }
    );

    return '1';
}

sub _build_runner {
    return Baseliner::RuleRunner->new(@_);
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event',     'BaselinerX::Type::Fieldlet',
        'BaselinerX::Type::Statement', 'BaselinerX::CI',
        'BaselinerX::Fieldlets',       'Baseliner::Model::Topic',
        'Baseliner::Model::Rules'
    );

    TestUtils->cleanup_cis;
    mdb->rule->drop;
}
