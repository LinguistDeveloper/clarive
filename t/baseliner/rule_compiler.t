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

    my $rule_compiler = _build_rule_compiler( dsl => 'do { return "hello"; }', id_rule => '123' );

    $rule_compiler->compile;

    ok $rule_compiler->is_compiled;
    ok $rule_compiler->is_loaded;

    my $package = $rule_compiler->package;

    is $package, 'Clarive::RULE_123';

    is $package->run, 'hello';

    $rule_compiler->unload;
};

subtest 'compile: compiles rule with version id' => sub {
    _setup();

    my $rule_compiler = _build_rule_compiler( dsl => 'do { return "hello"; }', id_rule => '123', version_id => 'haha' );

    $rule_compiler->compile;

    ok $rule_compiler->is_compiled;
    ok $rule_compiler->is_loaded;

    my $package = $rule_compiler->package;

    is $package, 'Clarive::RULE_123_haha';

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

    my $id_rule = TestSetup->create_rule();

    my $rule_compiler = _build_rule_compiler();

    $rule_compiler->compile;

    my $package = $rule_compiler->package;

    my $stash = {};
    my $ret = $package->call($id_rule, $stash);

    ok $ret;
    ok $stash->{_rule_elapsed};

    $rule_compiler->unload;
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
    TestUtils->setup_registry('BaselinerX::Type::Event', 'Baseliner::Model::Rules');

    mdb->rule->drop;
}

sub _build_rule_compiler {
    return Baseliner::RuleCompiler->new(@_);
}
