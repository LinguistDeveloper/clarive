use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::MonkeyMock;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;
use TestSetup;

use Baseliner::RuleCompiler;

use_ok 'BaselinerX::Service::JobDaemon';

subtest 'precompile_rule: precompiles rule' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule;

    my $service = _build_service();

    $service->precompile_rule($id_rule);

    my $rule = mdb->rule->find_one({id => $id_rule});
    ok( Baseliner::RuleCompiler->new( id_rule => $id_rule, version_id => '' . $rule->{_id} )->is_loaded );
};

done_testing;

sub _setup {
    TestUtils->cleanup_cis;

    TestUtils->setup_registry( 'BaselinerX::Type::Event', 'BaselinerX::CI', 'Baseliner::Model::Rules' );

    mdb->rule->drop;
}

sub _build_service {
    my (%params) = @_;

    return BaselinerX::Service::JobDaemon->new(@_);
}
