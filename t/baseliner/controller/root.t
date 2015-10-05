use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use TestEnv;
use TestUtils ':catalyst';

BEGIN {
    TestEnv->setup;
}

use Clarive::ci;
use Clarive::mdb;
use Baseliner::Core::Registry;
use Baseliner::Controller::Root;

my $api_key = '1234';

subtest 'authenticate with api_key' => sub {
    _setup();
    
    _register_auth_fail_events();

    my $controller = Baseliner::Controller::Root->new( application => '' );
    my $c = _build_c( req => { params => { username=>'test', api_key=>$api_key } }, authenticate=>{} );
    $c->stash->{api_key_authentication} = 1;
    ok $controller->auto($c);
};

subtest 'authentication denied with wrong api_key' => sub {
    _setup();

    _register_auth_fail_events();
    
    my $controller = Baseliner::Controller::Root->new( application => '' );
    my $c = _build_c( req => { params => { username=>'test', api_key=>'9999' } }, authenticate=>{} );
    $c->stash->{api_key_authentication} = 1;
    ok ! $controller->auto($c);
};

subtest 'authentication with api_key when option is not enabled' => sub {
    _setup();

    _register_auth_fail_events();
    
    my $controller = Baseliner::Controller::Root->new( application => '' );
    my $c = _build_c( req => { params => { username=>'test', api_key=>$api_key } }, authenticate=>{} );
    $c->stash->{api_key_authentication} = 0;
    ok ! $controller->auto($c);
};

sub _setup {
    Baseliner::Core::Registry->clear();
    TestUtils->register_ci_events();
    mdb->master->drop;
    mdb->master_rel->drop;
    mdb->master_doc->drop;

    my $user = ci->user->new( name => 'test', api_key=>$api_key );
    $user->save;
}

sub _build_c {
    mock_catalyst_c( username => 'test', @_ );
}

sub _register_auth_fail_events {
    require BaselinerX::Type::Event;
    Baseliner::Core::Registry->add_class( undef, 'event' => 'BaselinerX::Type::Event' );
    Baseliner::Core::Registry->add( 'Baseliner::Controller::Root', 'event.auth.failed', { foo => 'bar' } );
}

done_testing;
