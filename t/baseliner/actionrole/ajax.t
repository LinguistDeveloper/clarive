use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use TestEnv;
use TestUtils;

BEGIN {
    TestEnv->setup;
    $Carp::Verbose ++;
}

use Clarive::ci;
use Clarive::mdb;
use Baseliner::Core::Registry;
use Baseliner::Controller::User;
use Baseliner::Model::Permissions;

subtest 'infodetail: root user is allowed to query any user details' => sub {

};

sub _setup {
    Baseliner::Core::Registry->clear();
    mdb->master->drop;
    mdb->master_rel->drop;
    mdb->master_doc->drop;
}

sub _build_controller {
}

done_testing;

package FakeRequest;

use strict;
use warnings;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{params} = $params{params};

    return $self;
}

sub parameters { &params }
sub params     { shift->{params} }

package FakeResponse;

use strict;
use warnings;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    return $self;
}

sub status { }

package FakeContext;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{stash} = $params{stash} || {};
    $self->{req} = $params{req};

    return $self;
}

sub stash {
    my $self = shift;

    return $self->{stash} unless @_;

    if ( @_ == 1 ) {
        return $self->{stash}->{ $_[0] };
    }

    return $self->{stash}->{ $_[0] } = $_[1];
}

sub model {
    Baseliner::Model::Permissions->new();
}

sub username {
    shift->{username};
}

sub request { &req }
sub req     { shift->{req} }
sub res     { FakeResponse->new }
sub forward { 'FORWARD' }
