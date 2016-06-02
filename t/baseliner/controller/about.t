use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils ':catalyst', 'mock_time';
use TestSetup;

use JSON ();
use Capture::Tiny qw(capture);

use_ok 'Baseliner::Controller::About';

subtest 'show: return a license' => sub {


    my $controller = _build_controller();
    my $c = _build_c();

    $controller->show($c);

    my $date = DateTime->now();
    my $year = $date->year();
    my $mm = $c;

    is  $c->stash->{licenses}[0]->{text} =~ m/2010-$year/g, 1;

};

done_testing;

sub _build_c {
    mock_catalyst_c(
        username => 'root',
        @_
    );
}

sub _build_controller {
    Baseliner::Controller::About->new( application => '' );
}
