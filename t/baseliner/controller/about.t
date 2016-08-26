use strict;
use warnings;

use Test::More;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils ':catalyst';
use TestSetup;

use DateTime;

use_ok 'Baseliner::Controller::About';

subtest 'show: returns a license with updated current year' => sub {
    my $controller = _build_controller();

    my $c = _build_c();

    $controller->show($c);

    my $current_year = DateTime->now->year;

    like $c->stash->{licenses}[0]->{text}, qr/2010-$current_year/;
};

subtest 'show: returns customized icon' => sub {
    my $controller = _build_controller();

    my $c = _build_c( config => { logo_file => 'logo.svg' } );
    $controller->show($c);
    is $c->stash->{about_logo}, 'logo.svg';
};

subtest 'show: uses default logo' => sub {
    my $controller = _build_controller();

    my $c = _build_c();
    $controller->show($c);
    is $c->stash->{about_logo}, undef;
};

done_testing;

sub _build_c {
    mock_catalyst_c( username => 'root', @_ );
}

sub _build_controller {
    Baseliner::Controller::About->new( application => '' );
}
