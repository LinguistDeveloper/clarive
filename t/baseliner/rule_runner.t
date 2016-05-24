use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;
use TestSetup;

use JSON ();

use_ok 'Baseliner::RuleRunner';

subtest 'find_and_run_rule: runs rule' => sub {
    _setup();

    my $id_rule = _create_rule();

    my $runner = _build_runner();

    my $ret = $runner->find_and_run_rule( id_rule => $id_rule );

    cmp_deeply $ret,
      {
        ret => {
            stash => ignore(),
        },
        rule => {
            id          => $id_rule,
            version_id  => ignore(),
            version_tag => undef
        }
      };
};

subtest 'find_and_run_rule: runs rule by name' => sub {
    _setup();

    my $id_rule = _create_rule( rule_name => 'my rule' );

    my $runner = _build_runner();

    my $ret = $runner->find_and_run_rule( id_rule => 'my rule' );

    cmp_deeply $ret,
      {
        ret => {
            stash => ignore(),
        },
        rule => {
            id          => $id_rule,
            version_id  => ignore(),
            version_tag => undef
        }
      };
};

subtest 'find_and_run_rule: throws when unknown version tag' => sub {
    _setup();

    my $id_rule = _create_rule();

    my $runner = _build_runner();

    like exception { $runner->find_and_run_rule( id_rule => $id_rule, version_tag => '123' ) },
      qr/Version tag `123` of rule `1` not found/;
};

subtest 'find_and_run_rule: runs rule by version tag' => sub {
    _setup();

    my $id_rule = _create_rule();

    Baseliner::Model::Rules->new->write_rule(
        id_rule  => $id_rule,
        username => 'newuser',
    );

    my $runner = _build_runner();

    my @versions = Baseliner::Model::Rules->new->list_versions($id_rule);

    Baseliner::Model::Rules->new->tag_version( version_id => $versions[0]->{_id}, version_tag => 'production' );

    my $ret = $runner->find_and_run_rule( id_rule => $id_rule, version_tag => 'production' );

    cmp_deeply $ret->{rule},
      {
        id          => $id_rule,
        version_id  => ignore(),
        version_tag => 'production',
      };
};

subtest 'find_and_run_rule: runs rule by version id' => sub {
    _setup();

    my $id_rule = _create_rule();

    Baseliner::Model::Rules->new->write_rule(
        id_rule  => $id_rule,
        username => 'newuser',
    );

    my $runner = _build_runner();

    my @versions = Baseliner::Model::Rules->new->list_versions($id_rule);

    my $ret = $runner->find_and_run_rule( id_rule => $id_rule, version_id => '' . $versions[0]->{_id} );

    cmp_deeply $ret->{rule},
      {
        id          => $id_rule,
        version_id  => ignore(),
        version_tag => undef
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

    my $ret = $runner->run_dsl( dsl => $dsl, stash => $stash );

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

    my $dsl = 'print $stash->{foo}';
    my $stash = { foo => 'baz' };

    my $runner = _build_runner();

    my $ret = $runner->run_dsl( dsl => $dsl, stash => $stash );

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
            ),
            %params
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
    mdb->rule_version->drop;
}
