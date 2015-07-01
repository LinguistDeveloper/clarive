use strict;
use warnings;

use Test::More;

use lib 't/lib';
use TestEnv;

TestEnv->setup;

use_ok 'Baseliner::Model::Rules';

subtest 'does compile when config flag is conditional and rule is on' => sub {
    setup_db( rule_compile_mode => 'precompile' );

    my $rules = build_model();

    $rules->compile_rules( rule_precompile=>'depends' );

    my $cr = Baseliner::CompiledRule->new( id_rule => 1, @_ );
    ok $cr->package->can('meta');
    ok $cr->is_loaded;
    $cr->unload;
};

subtest 'does not compile when config flag is conditional and rule is off' => sub {
    setup_db( rule_compile_mode => 'none' );

    my $rules = build_model();

    $rules->compile_rules( rule_precompile=>'depends' );

    my $cr = Baseliner::CompiledRule->new( id_rule => 1, @_ );
    ok ! $cr->package->can('meta');
};

subtest 'does compile when config flag is on and rule is off' => sub {
    setup_db( rule_compile_mode => 'none' );

    my $rules = build_model();

    $rules->compile_rules( rule_precompile=>'always' );

    my $cr = Baseliner::CompiledRule->new( id_rule => 1, @_ );
    ok $cr->package->can('meta');
    ok $cr->is_loaded;
    $cr->unload;
};

subtest 'does compile when config flag is on and rule is on' => sub {
    setup_db( rule_compile_mode => 'precompile' );

    my $rules = build_model();

    $rules->compile_rules( rule_precompile=>'always' );

    my $cr = Baseliner::CompiledRule->new( id_rule => 1, @_ );
    ok $cr->package->can('meta');
    ok $cr->is_loaded;
    $cr->unload;
};

subtest 'does not compile when config flag is off and rule is on' => sub {
    setup_db( rule_compile_mode => 'precompile' );

    my $rules = build_model();

    $rules->compile_rules( rule_precompile=>'none' );

    my $cr = Baseliner::CompiledRule->new( id_rule => 1, @_ );
    ok ! $cr->package->can('meta');
};

subtest 'does not compile when config flag is off and rule is off' => sub {
    setup_db( rule_compile_mode => 'none' );

    my $rules = build_model();

    $rules->compile_rules( rule_precompile=>'none' );

    my $cr = Baseliner::CompiledRule->new( id_rule => 1, @_ );
    ok ! $cr->package->can('meta');
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

sub build_model {
    return Baseliner::Model::Rules->new();
}

done_testing;
