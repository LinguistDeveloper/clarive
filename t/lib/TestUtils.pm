package TestUtils;

use strict;
use warnings;

use base 'Exporter';

our @EXPORT_OK = qw(mock_catalyst_req mock_catalyst_res mock_catalyst_c mock_time);
our %EXPORT_TAGS = ( 'catalyst' => [qw/mock_catalyst_req mock_catalyst_res mock_catalyst_c/] );

use Carp;
use Class::Load ();
use Class::Refresh ();
use Clarive::mdb;
use Clarive::ci;
use Test::MockTime qw(set_absolute_time restore_time);

sub cleanup_cis {
    my $class = shift;

    mdb->master->drop;
    mdb->master_doc->drop;
    mdb->master_rel->drop;
}

sub registry {
    'Baseliner::Core::Registry';
}

sub register_ci_events {
    my $class = shift;

    require BaselinerX::Type::Event;

    $class->registry->add_class( undef, 'event' => 'BaselinerX::Type::Event' );
    $class->registry->add( 'BaselinerX::CI', 'event.ci.create', { foo => 'bar' } );
    $class->registry->add( 'BaselinerX::CI', 'event.ci.update', { foo => 'bar' } );
    $class->registry->add( 'BaselinerX::CI', 'event.ci.delete', { foo => 'bar' } );
}

sub reload_module {
    my $class = shift;
    my ($module) = @_;

    Class::Refresh->refresh_module($module);
}

sub clear_registry {
    Baseliner::Core::Registry->clear();
}

sub setup_registry {
    my $class = shift;
    my (@modules) = @_;

    $class->clear_registry;
    $class->reload_module($_) for @modules;
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

package FakeLogger;
sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    return $self;
}
sub debug {}
sub info {}
sub error {}

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
    $self->{path}    = $params{path} || '/';

    foreach my $key (keys %{$self->{headers}}) {
        $self->{headers}->{lc($key)} = delete $self->{headers}->{$key};
    }

    return $self;
}

sub content_type {'text/html'}
sub user_agent { 'Mozilla/1.0' }
sub address { '127.0.0.1' }
sub parameters { &params }
sub query_parameters { &params }
sub params     { shift->{params} }
sub path       { shift->{path} }
sub headers    { shift->{headers} }

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
sub headers {
    my $self = shift;

    $self->{headers} ||= FakeHeaders->new;

    return $self->{headers};
}

package FakeContext;

use Carp;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{stash}        = $params{stash} || {};
    $self->{session}      = $params{session} || {};
    $self->{req}          = $params{req};
    $self->{username}     = $params{username};
    $self->{model}        = $params{model};
    $self->{config}       = $params{config} || {};
    $self->{authenticate} = $params{authenticate};

    return $self;
}

sub user_languages { ('en') }
sub languages {}

sub config { shift->{config} }

sub stash {
    my $self = shift;

    return $self->{stash} unless @_;

    if ( @_ == 1 ) {
        return $self->{stash}->{ $_[0] };
    }

    return $self->{stash}->{ $_[0] } = $_[1];
}

sub session {
    my $self = shift;

    return $self->{session} unless @_;

    if ( @_ == 1 ) {
        return $self->{session}->{ $_[0] };
    }

    return $self->{session}->{ $_[0] } = $_[1];
}

sub model {
    my $self = shift;
    my ($model_name) = @_;

    my $model_class;
    if (ref $self->{model} eq 'HASH') {
        $model_class = $self->{model}->{$model_name};
    }
    else {
        $model_class = $self->{model};
    }

    return $model_class if ref $model_class;

    croak 'no model defined' unless $model_class;

    Class::Load::load_class($model_class);

    return $model_class->new;
}

sub user         { shift->{user} }
sub username     { shift->{username} }
sub authenticate { 
    my $self = shift;

    my $auth = $self->{authenticate};

    if ($auth && $auth->{id}) {
        $self->{username} = $auth->{id};
    }

    return $auth;
}

sub request { &req }
sub response{ &res }
sub req     { shift->{req} || FakeRequest->new }
sub res     { FakeResponse->new }
sub forward { 'FORWARD' }
sub log { FakeLogger->new }
sub logout {}
sub full_logout {}

sub user_ci {
    my ($c,$username) = @_;

    $username //= $c->username;
    return unless $username;

    ci->user->search_ci( name=>( $username ) );
}

package FakeHeaders;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{headers} = {%params};

    return $self;
}

sub header {
    my $self = shift;
    my ($key) = @_;

    return $self->{headers}->{$key};
}

1;
