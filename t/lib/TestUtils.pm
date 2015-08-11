package TestUtils;

use strict;
use warnings;

use base 'Exporter';

our @EXPORT_OK = qw(mock_catalyst_req mock_catalyst_res mock_catalyst_c mock_time);
our %EXPORT_TAGS = ( 'catalyst' => [qw/mock_catalyst_req mock_catalyst_res mock_catalyst_c/] );

use Carp;
use Class::Load ();
use Clarive::mdb;
use Clarive::ci;
use Test::MockTime qw(set_absolute_time restore_time);

sub cleanup_cis {
    my $class = shift;

    mdb->master->drop;
    mdb->master_doc->drop;
    mdb->master_rel->drop;
}

sub create_amazon_account {
    my $class = shift;

    my $account = ci->amazon_account->new(
        mid        => "1",
        access_key => 'ACCESS KEY',
        secret_key => 'SECRET KEY',
        region     => 'us-west-2',
        active     => 1,
        @_
    );
    $account->save;
    return $account;
}

sub create_amazon_instance {
    my $class = shift;

    my $instance = ci->amazon_instance->new(
        mid         => "2",
        instance_id => 'i-1234567890',
        @_
    );
    $instance->save;
    return $instance;
}

sub mock_catalyst_req {
    FakeRequest->new(@_);
}

sub mock_catalyst_res {
    FakeResponse->new(@_);
}

sub mock_catalyst_c {
    my (%params) = @_;

    if ( $params{req} && ref $params{req} eq 'HASH' ) {
        $params{req} = mock_catalyst_req( %{ delete $params{req} } );
    }

    FakeContext->new(%params);
}

sub mock_time {
    my ($time,$cb) = @_;
    set_absolute_time($time);
    $cb->();
    restore_time();
}

package FakeRequest;

use strict;
use warnings;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{params}  = $params{params};
    $self->{headers} = $params{headers} || {};

    foreach my $key (keys %{$self->{headers}}) {
        $self->{headers}->{lc($key)} = delete $self->{headers}->{$key};
    }

    return $self;
}

sub parameters { &params }
sub params     { shift->{params} }

sub header {
    my $self = shift;
    my ($key) = @_;

    return $self->{headers}->{$key};
}

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

use Carp;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{stash}    = $params{stash} || {};
    $self->{req}      = $params{req};
    $self->{username} = $params{username};
    $self->{model}    = $params{model};
    $self->{config}   = $params{config} || {};

    return $self;
}

sub config { shift->{config} }

sub stash {
    my $self = shift;

    return $self->{stash} unless @_;

    if ( @_ == 1 ) {
        return $self->{stash}->{ $_[0] };
    }

    return $self->{stash}->{ $_[0] } = $_[1];
}

sub model {
    my $self = shift;

    my $model_class = $self->{model};
    croak 'no model defined' unless $model_class;

    Class::Load::load_class($model_class);

    return $model_class->new;
}

sub username { shift->{username} }

sub request { &req }
sub req     { shift->{req} || FakeRequest->new }
sub res     { FakeResponse->new }
sub forward { 'FORWARD' }

1;
