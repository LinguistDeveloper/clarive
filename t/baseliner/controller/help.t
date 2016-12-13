use strict;
use warnings;
use utf8;

use Test::More;
use Test::Deep;

use Carp;
use Cwd ();
my $root;

BEGIN {
    use File::Basename qw(dirname);
    $root = Cwd::realpath( dirname(__FILE__) );
}

use TestEnv;
BEGIN {
    TestEnv->setup( base => "$root/../../data/app-base", home => "$root/../../data/app-base/app-home" );
}
use TestUtils ':catalyst';

use_ok 'Baseliner::Controller::Help';

subtest 'docs_tree: help tree is built from directory' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c();

    $controller->docs_tree($c);
    is ref $c->stash->{json}, 'ARRAY';
    is scalar @{ $c->stash->{json} }, 5;
};

subtest 'docs_tree: gets user language from user preferences' => sub {
    _setup();

    TestUtils->create_ci( 'user', name => 'developer', language_pref => 'es' );

    my $controller = _build_controller();

    my $c = _build_c( username => 'developer' );

    $controller->docs_tree($c);

    is $c->stash->{json}->[0]->{text}, 'Extraña Ayuda Test';
};

subtest 'get_doc: doc retrieval from file' => sub {
        _setup();

        my $controller = _build_controller();

        my $c = _build_c( req => { params => { path => 'test.markdown' } } );

        $controller->get_doc($c);

        is $c->stash->{json}->{data}->{title}, 'Help Test';
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::CI',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Service',
        'BaselinerX::Type::Statement',
    );

    TestUtils->cleanup_cis;
}

sub _build_c {
    mock_catalyst_c(@_);
}

sub _build_controller {
    my (%params) = @_;

    return Baseliner::Controller::Help->new( application => '' );
}
