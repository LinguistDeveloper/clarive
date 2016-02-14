use strict;
use warnings;

use Test::More;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }

use JSON ();
use Baseliner::Role::CI;
use Baseliner::Core::Registry;
use BaselinerX::Type::Statement;

use_ok 'Baseliner::CompiledRule';

subtest 'compile: compiles temp rule' => sub {
    _setup();

    my $cr = _build_compiled_rule(id_rule => undef, dsl => 'do { return "hello"; }');

    ok $cr->is_temp_rule;

    $cr->compile;

    my $package = $cr->package;

    like $package, qr/Clarive::RULE_[a-f0-9]+/;

    is $package->run, 'hello';

    $cr->unload;
};

subtest 'compile: compiles rule' => sub {
    _setup();

    my $cr = _build_compiled_rule();

    $cr->compile;

    ok $cr->is_compiled;
    ok $cr->is_loaded;

    my $package = $cr->package;

    is $package, 'Clarive::RULE_1';

    is $package->run({job_step => 'RUN'}), 'hi there';

    $cr->unload;
};

subtest 'compile: returns info' => sub {
    _setup();

    my $cr = _build_compiled_rule();

    my $ret = $cr->compile;

    cmp_deeply $ret, { err => '', t => re(qr/\d+\.\d+/) };

    $cr->unload;
};

subtest 'compile: recompiles if dsl changed' => sub {
    _setup();

    my $cr = _build_compiled_rule();

    $cr->compile;

    is $cr->package->run({job_step => 'RUN'}), 'hi there';

    mdb->rule->update(
        { id => '1' },
        {
            '$set' => {
                "ts"      => "2016-01-01 13:42:57",
                rule_tree => JSON::encode_json(
                    [
                        {
                            "attributes" => {
                                "leaf"           => \1,
                                "nested"         => 0,
                                "holds_children" => \0,
                                "run_sub"        => \1,
                                "palette"        => \0,
                                "text"           => "CODE",
                                "key"            => "statement.perl.code",
                                "name"           => "CODE",
                                "data"           => { "code" => "do {return 'new stuff'}" },
                                "ts"             => "2016-01-01 13:42:57",
                                "who"            => "root",
                                "expanded"       => \0
                            },
                            "children" => []
                        }
                    ]
                )
            }
        }
    );

    $cr->compile;

    is $cr->package->run, 'new stuff';

    $cr->unload;
};

subtest 'compile: do not recompile if nothing changed' => sub {
    _setup();

    my $cr = _build_compiled_rule();

    $cr->compile;

    my $ret = $cr->compile;

    is_deeply $ret, {err => '', t => ''};

    $cr->unload;
};

subtest 'compile: compiles rule from another version' => sub {
    _setup();

    my $version = mdb->rule_version->insert(
        {
            id_rule   => '1',
            rule_tree => JSON::encode_json(
                [
                    {
                        "attributes" => {
                            "leaf"           => \1,
                            "nested"         => 0,
                            "holds_children" => \0,
                            "run_sub"        => \1,
                            "palette"        => \0,
                            "text"           => "CODE",
                            "key"            => "statement.perl.code",
                            "name"           => "CODE",
                            "data"           => { "code" => "do {return 'bye there'}" },
                            "ts"             => "2015-06-30T13=>42=>57",
                            "who"            => "root",
                            "expanded"       => \0
                        },
                        "children" => []
                    }
                ]
            )
        }
    );

    my $cr = _build_compiled_rule(rule_version => $version);

    $cr->compile;

    my $package = $cr->package;

    like $package, qr/Clarive::RULE_1_[a-f0-9]+/;

    is $package->run, 'bye there';

    $cr->unload;
};

subtest 'run: runs rule' => sub {
    _setup();

    my $cr = _build_compiled_rule();

    $cr->compile;
    my $ret = $cr->run( stash => { job_step => 'RUN' } );

    is $cr->return_value, 'hi there';
    is $cr->warnings,     '';
    is $cr->errors,       '';

    is_deeply $ret, {ret => 'hi there', err => ''};

    $cr->unload;
};

subtest 'run: calls another rule' => sub {
    _setup();

    my $code = 'return call(1, $stash);';
    mdb->rule->insert(
        {
            id                => '2',
            "rule_active"     => "1",
            "wsdl"            => "",
            "rule_type"       => "chain",
            "rule_desc"       => "",
            "authtype"        => "required",
            "rule_name"       => "test2",
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

    my $cr = _build_compiled_rule(id_rule => '2');

    $cr->compile;
    $cr->run( stash => { job_step => 'RUN' } );

    is $cr->return_value, 'hi there';

    $cr->unload;

    _build_compiled_rule(id_rule => 1)->unload;
};

subtest 'catches compile errors' => sub {
    _setup( code => q{bareword} );

    my $cr = _build_compiled_rule();

    $cr->compile;
    $cr->run( stash => { job_step => 'RUN' } );

    ok !defined $cr->return_value;
    like $cr->compile_error, qr/Bareword "bareword"/;
    like $cr->errors, qr/Bareword "bareword"/;

    $cr->unload;
};

subtest 'catches runtime errors' => sub {
    _setup( code => q{die 'here'} );

    my $cr = _build_compiled_rule();

    $cr->compile;
    $cr->run( stash => { job_step => 'RUN' } );

    # WTF? return_value is the same as runtime_error
    like $cr->return_value, qr/here/;

    like $cr->runtime_error, qr/here/;
    like $cr->errors, qr/here/;

    $cr->unload;
};

subtest 'unloads rule' => sub {
    _setup();

    my $cr = _build_compiled_rule();

    my $package = $cr->package;

    $cr->compile;
    $cr->unload;

    ok !$cr->is_loaded;
    ok !$package->can('meta');
};

subtest 'unloads temp rule on DESTROY' => sub {
    _setup();

    my $cr = _build_compiled_rule(id_rule => undef, dsl => 'do {}');

    $cr->compile;

    my $package = $cr->package;

    undef $cr;

    ok !$package->can('meta');
};

sub _setup {
    my (%params) = @_;

    Baseliner::Core::Registry->clear;

    _register_statements();

    my $code = $params{code} || q%return 'hi there';%;

    mdb->rule->drop;
    mdb->rule->insert(
        {
            id                => '1',
            "rule_active"     => "1",
            "rule_type"       => "chain",
            "rule_desc"       => "",
            "rule_name"       => "test",
            "ts"              => "2015-06-30 13:44:11",
            "username"        => "root",
            "rule_seq"        => 1,
            "rule_when"       => "promote",
            "rule_tree" =>
qq%[{"attributes":{"text":"CHECK","icon":"/static/images/icons/job.png","key":"statement.step","expanded":true,"leaf":false,"id":"xnode-1023"},"children":[]},{"attributes":{"key":"statement.step","expanded":true,"leaf":false,"icon":"/static/images/icons/job.png","text":"INIT","id":"xnode-1024"},"children":[]},{"attributes":{"key":"statement.step","expanded":true,"leaf":false,"text":"PRE","icon":"/static/images/icons/job.png","id":"xnode-1025"},"children":[]},{"attributes":{"icon":"/static/images/icons/job.png","text":"RUN","leaf":false,"key":"statement.step","expanded":true,"id":"xnode-1026"},"children":[{"attributes":{"icon":"/static/images/icons/cog.png","on_drop_js":null,"on_drop":"","leaf":true,"nested":0,"holds_children":false,"run_sub":true,"palette":false,"text":"CODE","key":"statement.perl.code","id":"rule-ext-gen1029-1435664566485","name":"CODE","data":{"code":"$code"},"ts":"2015-06-30T13:42:57","who":"root","expanded":false},"children":[]}]},{"attributes":{"leaf":false,"key":"statement.step","expanded":true,"text":"POST","icon":"/static/images/icons/job.png","id":"xnode-1027"},"children":[]}]%
        }
    );
}

sub _register_statements {
    Baseliner::Core::Registry->add_class( undef, 'statement' => 'BaselinerX::Type::Statement' );

    Baseliner::Core::Registry->add(
        'main',
        'statement.step' => {
            dsl => sub {
                my ( $self, $n, %p ) = @_;
                sprintf(
                    q{
            if( $stash->{job_step} eq q{%s} ) {
                %s
            }
        }, $n->{text}, $self->dsl_build( $n->{children}, %p )
                );
            }
        }
    );

    Baseliner::Core::Registry->add(
        'main',
        'statement.perl.code' => {
            data => { code => '' },
            dsl  => sub {
                my ( $self, $n, %p ) = @_;
                sprintf( q{ %s; }, $n->{code} // '' );
            },
        }
    );
}

sub _build_compiled_rule {
    return Baseliner::CompiledRule->new( id_rule => '1', @_ );
}

done_testing;
