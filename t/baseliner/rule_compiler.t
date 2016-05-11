use strict;
use warnings;

use Test::More;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }

use_ok 'Baseliner::RuleCompiler';

subtest 'compile: compiles temp rule' => sub {
    _setup();

    my $cr = _build_rule_compiler( dsl => 'do { return "hello"; }', is_temp_rule => 1 );

    $cr->compile;

    my $package = $cr->package;

    like $package, qr/Clarive::RULE_[a-f0-9]+/;

    is $package->run, 'hello';

    $cr->unload;
};

subtest 'compile: compiles rule' => sub {
    _setup();

    my $cr = _build_rule_compiler( dsl => 'do { return "hello"; }', suffix => '123' );

    $cr->compile;

    ok $cr->is_compiled;
    ok $cr->is_loaded;

    my $package = $cr->package;

    is $package, 'Clarive::RULE_123';

    is $package->run, 'hello';

    $cr->unload;
};

subtest 'compile: returns info' => sub {
    _setup();

    my $cr = _build_rule_compiler();

    my $ret = $cr->compile;

    cmp_deeply $ret, { err => '', t => re(qr/\d+\.\d+/) };

    $cr->unload;
};

subtest 'catches compile errors' => sub {
    _setup();

    my $cr = _build_rule_compiler( dsl => 'bareword' );

    $cr->compile;
    $cr->run( stash => { job_step => 'RUN' } );

    ok !defined $cr->return_value;
    like $cr->compile_error, qr/Bareword "bareword"/;
    like $cr->errors,        qr/Bareword "bareword"/;

    $cr->unload;
};

subtest 'catches runtime errors' => sub {
    _setup();

    my $cr = _build_rule_compiler( dsl => q{die 'here'} );

    $cr->compile;
    $cr->run( stash => { job_step => 'RUN' } );

    # WTF? return_value is the same as runtime_error
    like $cr->return_value, qr/here/;

    like $cr->runtime_error, qr/here/;
    like $cr->errors,        qr/here/;

    $cr->unload;
};

subtest 'unloads rule' => sub {
    _setup();

    my $cr = _build_rule_compiler();

    my $package = $cr->package;

    $cr->compile;
    $cr->unload;

    ok !$cr->is_loaded;
    ok !$package->can('meta');
};

subtest 'unloads temp rule on DESTROY' => sub {
    _setup();

    my $cr = _build_rule_compiler( dsl => 'do {}', is_temp_rule => 1 );

    $cr->compile;

    my $package = $cr->package;

    undef $cr;

    ok !$package->can('meta');
};

done_testing;

sub _setup {
    my (%params) = @_;

}

sub _build_rule_compiler {
    return Baseliner::RuleCompiler->new(@_);
}
