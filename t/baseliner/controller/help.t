use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MonkeyMock;
use TestEnv;
use TestUtils ':catalyst';

use Carp;
my $root;
BEGIN {
    use File::Basename qw(dirname);
    $root = Cwd::realpath( dirname(__FILE__) );
}

BEGIN {
    TestEnv->setup( base=>"$root/../../data/app-base", home=>"$root/../../data/app-base/app-home" );
}

use Baseliner::Core::Registry;
use Baseliner::Controller::Help;
use Baseliner::Model::Help;

subtest 'docs_tree: help tree is built from directory' => sub {
    _setup();

    my $help = _mock_help();
    #$help->mock( build_doc_tree => sub { } );
    my $controller = _build_controller( help => $help );

    my $c = _build_c( req => { params => { query=>'' } } );

    $controller->docs_tree($c);   
    is ref $c->stash->{json}, 'ARRAY'; 
    is scalar @{ $c->stash->{json} }, 2;
};

subtest 'get_doc: doc retrieval from file' => sub {
    _setup();

    my $help = _mock_help();
    #$help->mock( build_doc_tree => sub { } );
    my $controller = _build_controller( help => $help );

    my $c = _build_c( req => { params => { path=>'test.markdown' } } );

    $controller->get_doc($c);
    #use YAML; warn YAML::Dump( $c->stash );
    is ref $c->stash->{json}, 'HASH'; 
    is $c->stash->{json}{data}{title}, 'Help Test'; 
};

done_testing;

sub _setup {
    TestUtils->setup_registry();
}

sub _mock_user_ci {
    my $user_ci = Test::MonkeyMock->new;
    $user_ci->mock( from_user_date => sub { $_[1] } );
    return $user_ci;
}

sub _build_c {
    mock_catalyst_c( user_ci => _mock_user_ci(), path_to=>sub{ }, @_ );
}

sub _mock_help {
    my (%params) = @_;

    my $help = Baseliner::Model::Help->new;
    $help = Test::MonkeyMock->new($help);
    return $help;
}

sub _build_controller {
    my (%params) = @_;

    my $help = $params{help} || _mock_help();
    my $controller = Baseliner::Controller::Help->new( application => '' );
    $controller = Test::MonkeyMock->new($controller);
    $controller->mock( _build_help => sub { $help } );
    return $controller;
}
