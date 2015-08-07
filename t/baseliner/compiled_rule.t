use strict;
use warnings;

use Test::More;

use lib 't/lib';
use TestEnv;

TestEnv->setup;

use Baseliner::Role::CI;

use_ok 'Baseliner::CompiledRule';

subtest 'returns default values' => sub {
    my $cr = Baseliner::CompiledRule->new();

    ok !$cr->is_loaded;
    ok !$cr->is_compiled;
    is $cr->errors,   '';
    is $cr->warnings, '';
    ok $cr->is_temp_rule;
    ok !defined $cr->doc;
};

subtest 'compiles rule' => sub {
    setup_db();

    my $cr = build_compiled_rule();

    $cr->compile;

    ok $cr->is_compiled;
    ok $cr->is_loaded;

    my $package = $cr->package;
    ok $package->can('isa');

    $cr->unload;
};

subtest 'builds package name' => sub {
    setup_db();

    my $cr = build_compiled_rule();

    is $cr->package, 'Clarive::RULE_1';

    $cr->unload;
};

subtest 'runs rule' => sub {
    setup_db();

    my $cr = build_compiled_rule();

    $cr->compile;
    $cr->run( stash => { job_step => 'RUN' } );

    is $cr->return_value, 'hi there';

    $cr->unload;
};

subtest 'calls another rule' => sub {
    setup_db();

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

    my $cr = build_compiled_rule(id_rule => 2);

    $cr->compile;
    $cr->run( stash => { job_step => 'RUN' } );

    is $cr->return_value, 'hi there';

    $cr->unload;

    build_compiled_rule(id_rule => 1)->unload;
};

subtest 'catches compile errors' => sub {
    setup_db( code => q{bareword} );

    my $cr = build_compiled_rule();

    $cr->compile;
    $cr->run( stash => { job_step => 'RUN' } );

    ok !defined $cr->return_value;
    like $cr->compile_error, qr/Bareword "bareword"/;
    like $cr->errors, qr/Bareword "bareword"/;

    $cr->unload;
};

subtest 'catches runtime errors' => sub {
    setup_db( code => q{die 'here'} );

    my $cr = build_compiled_rule();

    $cr->compile;
    $cr->run( stash => { job_step => 'RUN' } );

    # WTF? return_value is the same as runtime_error
    like $cr->return_value, qr/here/;

    like $cr->runtime_error, qr/here/;
    like $cr->errors, qr/here/;

    $cr->unload;
};

subtest 'unloads rule' => sub {
    setup_db();

    my $cr = build_compiled_rule();

    my $package = $cr->package;

    $cr->compile;
    $cr->unload;

    ok !$cr->is_loaded;
    ok !$package->can('meta');
};

subtest 'creates temp rule' => sub {
    my $cr = Baseliner::CompiledRule->new();

    # WTF? this has to be called
    $cr->id_rule;

    ok $cr->is_temp_rule;
    like $cr->id_rule, qr/^[a-f0-9]+$/;
};

subtest 'unloads temp rule on DESTROY' => sub {
    setup_db();

    my $cr = build_compiled_rule();
    $cr->is_temp_rule(1);

    $cr->compile;

    my $package = $cr->package;

    undef $cr;

    ok !$package->can('meta');
};

sub setup_db {
    my (%params) = @_;

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

sub build_compiled_rule {
    return Baseliner::CompiledRule->new( id_rule => 1, @_ );
}

done_testing;
