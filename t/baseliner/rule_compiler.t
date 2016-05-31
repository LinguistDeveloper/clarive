use strict;
use warnings;

use Test::More;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;
use TestSetup;

use_ok 'Baseliner::RuleCompiler';

subtest 'compile: compiles temp rule' => sub {
    _setup();

    my $rule_compiler = _build_rule_compiler( dsl => 'do { return "hello"; }' );

    $rule_compiler->compile;

    ok $rule_compiler->is_compiled;

    my $package = $rule_compiler->package;
    like $package, qr/Clarive::RULE_[a-f0-9]+/;

    my $ret = $rule_compiler->run( stash => {} );

    is_deeply $ret, { ret => 'hello', err => '' };

    $rule_compiler->unload;
};

subtest 'compile: compiles rule with passed ts' => sub {
    _setup();

    my $rule_compiler = _build_rule_compiler( dsl => 'do { return "hello"; }', ts => 123 );

    $rule_compiler->compile;

    my $package = $rule_compiler->package;

    is $package->ts, '123';

    $rule_compiler->unload;
};

subtest 'compile: compiles rule' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule(
        rule_tree => [
            {
                "attributes"=> {
                    "icon"=> "/static/images/icons/cog_perl.png",
                    "key"=> "statement.code.server",
                    "text"=> "Server CODE",
                    "id"=> "rule-ext-gen38276-1456842988061",
                    "name"=> "Server CODE",
                    "data"=> {
                        "lang"=> "perl",
                        "code"=> q{
                            return 'hello';
                        }
                    },
                },
                "children"=> [],
            }
        ]
    );

    my $rule_compiler = _build_rule_compiler( id_rule => $id_rule );

    $rule_compiler->compile;

    ok $rule_compiler->is_compiled;
    ok $rule_compiler->is_loaded;

    my $package = $rule_compiler->package;

    is $package, "Clarive::RULE_$id_rule";

    is $package->run, 'hello';

    $rule_compiler->unload;
};

subtest 'compile: compiles rule with version id' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule(
        rule_tree => [
            {
                "attributes"=> {
                    "icon"=> "/static/images/icons/cog_perl.png",
                    "key"=> "statement.code.server",
                    "text"=> "Server CODE",
                    "id"=> "rule-ext-gen38276-1456842988061",
                    "name"=> "Server CODE",
                    "data"=> {
                        "lang"=> "perl",
                        "code"=> q{
                            return 'hello';
                        }
                    },
                },
                "children"=> [],
            }
        ]
    );

    my $rule_compiler = _build_rule_compiler( id_rule => $id_rule, version_id => 'haha' );

    $rule_compiler->compile;

    ok $rule_compiler->is_compiled;
    ok $rule_compiler->is_loaded;

    my $package = $rule_compiler->package;

    is $package, "Clarive::RULE_${id_rule}_haha";

    is $package->run, 'hello';

    $rule_compiler->unload;
};

subtest 'compile: returns info' => sub {
    _setup();

    my $rule_compiler = _build_rule_compiler();

    my $ret = $rule_compiler->compile;

    cmp_deeply $ret, { err => '', t => re(qr/\d+\.\d+/) };

    $rule_compiler->unload;
};

subtest 'compile: builds package with call method' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_with_code( code => '$stash->{foo}++' );

    my $rule_compiler = _build_rule_compiler();

    $rule_compiler->compile;

    my $package = $rule_compiler->package;

    my $stash = { foo => 1 };
    my $ret = $package->call( $id_rule, $stash );

    ok $ret;
    ok $stash->{_rule_elapsed};
    is $stash->{foo}, 2;

    $rule_compiler->unload;
};

subtest 'compile: does not recompile already compiled rule' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule(rule_tree => []);

    my $rule_compiler = _build_rule_compiler(id_rule => $id_rule, ts => '2016-01-01 00:00:00');
    $rule_compiler->compile;

    $rule_compiler = _build_rule_compiler(id_rule => $id_rule, ts => '2016-01-01 00:00:00');
    $rule_compiler->compile;

    my $package = $rule_compiler->package;

    $rule_compiler->unload;

    is $rule_compiler->compile_status, 'fresh';
};

subtest 'compile: recompiles modifed rule' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule();

    my $rule_compiler = _build_rule_compiler(id_rule => $id_rule, ts => '2016-01-01 00:00:00');
    $rule_compiler->compile;

    mdb->rule->update({id => "$id_rule"}, {'$set' => {ts => '2016-01-01 00:00:01'}});

    $rule_compiler = _build_rule_compiler(id_rule => $id_rule, ts => '2016-01-01 00:00:00');
    $rule_compiler->compile;

    my $package = $rule_compiler->package;

    $rule_compiler->unload;

    is $rule_compiler->compile_status, 'recompiling';
};

subtest 'catches compile errors' => sub {
    _setup();

    my $rule_compiler = _build_rule_compiler( dsl => 'bareword' );

    $rule_compiler->compile;
    $rule_compiler->run( stash => { job_step => 'RUN' } );

    ok !defined $rule_compiler->return_value;
    like $rule_compiler->compile_error, qr/Bareword "bareword"/;
    like $rule_compiler->errors,        qr/Bareword "bareword"/;

    $rule_compiler->unload;
};

subtest 'catches runtime errors' => sub {
    _setup();

    my $rule_compiler = _build_rule_compiler( dsl => q{die 'here'} );

    $rule_compiler->compile;
    $rule_compiler->run( stash => { job_step => 'RUN' } );

    # WTF? return_value is the same as runtime_error
    like $rule_compiler->return_value, qr/here/;

    like $rule_compiler->runtime_error, qr/here/;
    like $rule_compiler->errors,        qr/here/;

    $rule_compiler->unload;
};

subtest 'unloads rule' => sub {
    _setup();

    my $rule_compiler = _build_rule_compiler();

    my $package = $rule_compiler->package;

    $rule_compiler->compile;
    $rule_compiler->unload;

    ok !$rule_compiler->is_loaded;
    ok !$package->can('meta');
};

subtest 'unloads temp rule on DESTROY' => sub {
    _setup();

    my $rule_compiler = _build_rule_compiler( dsl => 'do {}', is_temp_rule => 1 );

    $rule_compiler->compile;

    my $package = $rule_compiler->package;

    undef $rule_compiler;

    ok !$package->can('meta');
};

done_testing;

sub _setup {
    TestUtils->setup_registry( 'BaselinerX::Type::Event', 'BaselinerX::Type::Statement', 'Baseliner::Model::Rules' );

    mdb->rule->drop;
    mdb->rule_version->drop;
}

sub _build_rule_compiler {
    return Baseliner::RuleCompiler->new(@_);
}
