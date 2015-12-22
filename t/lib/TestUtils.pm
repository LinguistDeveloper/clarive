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
use Time::Local;
use Time::Piece;
use Test::MockTime qw(set_absolute_time restore_time);
use Test::TempDir::Tiny;
use TestGit;

sub cleanup_cis {
    my $class = shift;

    mdb->master->drop;
    mdb->master_doc->drop;
    mdb->master_rel->drop;
    mdb->collection('seq')->drop;
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

sub create_ci {
    my $class = shift;
    my $name = shift;

    my $ci_class = 'BaselinerX::CI::' . $name;
    Class::Load::load_class($ci_class);

    my $ci = $ci_class->new(@_);
    $ci->save;

    return $ci;
}

sub create_ci_project {
    my $class = shift;

    return $class->create_ci('project', name => 'Project', @_);
}

sub create_ci_topic {
    my $class = shift;

    return $class->create_ci('topic', @_);
}

sub create_ci_GitRepository {
    my $class = shift;

    my $dir = TestGit->create_repo;

    return $class->create_ci('GitRepository', repo_dir => "$dir/.git", @_);
}

sub clear_registry {
    Baseliner::Core::Registry->clear();
}

sub setup_registry {
    my $class = shift;
    my (@modules) = @_;

    $class->clear_registry;
    Class::Load::load_class($_) for @modules;
    $class->reload_module($_) for @modules;
}

sub random_string {
    my $class = shift;
    my ($len) = @_;

    $len ||= 10;

    my @alpha = ('0' .. '9', 'a' .. 'z');

    my $text = '';
    $text .= $alpha[int(rand(@alpha))] for 1 .. $len;

    return $len;
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
    my ($time, $cb) = @_;

    my @t = localtime(time);
    my $gmt_offset_in_seconds = timegm(@t) - timelocal(@t);

    my $epoch = $time =~ m/^\d+$/ ? $time : Time::Piece->strptime($time, '%Y-%m-%dT%TZ')->epoch;
    $epoch -= $gmt_offset_in_seconds;

    set_absolute_time($epoch);

    $cb->();

    restore_time();
}

sub write_file {
    my $class = shift;
    my ($content, $filename) = @_;

    open my $fh, '>', $filename or die $!;
    print $fh $content;
    close $fh;
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

    $self->{uri}     = $params{uri};
    $self->{method}  = $params{method} || 'GET';
    $self->{params}  = $params{params};
    $self->{headers} = $params{headers} || {};
    $self->{path}    = $params{path} || '/';
    $self->{body}    = $params{body} || '';

    foreach my $key (keys %{$self->{headers}}) {
        $self->{headers}->{lc($key)} = delete $self->{headers}->{$key};
    }

    return $self;
}

sub uri              { shift->{uri} || 'http://localhost' }
sub content_type     { 'text/html' }
sub user_agent       { 'Mozilla/1.0' }
sub address          { '127.0.0.1' }
sub parameters       { &params }
sub query_parameters { &params }
sub params           { shift->{params} }
sub path             { shift->{path} }
sub headers          { shift->{headers} }
sub method           { shift->{method} }
sub body             { shift->{body} }

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

sub headers {
    my $self = shift;

    $self->{headers} ||= FakeHeaders->new;

    return $self->{headers};
}

sub status {
    my $self = shift;

    return $self->{status} unless @_;

    $self->{status} = $_[0];

    return $self;
}

sub content_type {
    my $self = shift;

    return $self->{content_type} unless @_;

    $self->{content_type} = $_[0];

    return $self;
}

sub body {
    my $self = shift;

    return $self->{body} unless @_;

    $self->{body} = $_[0];

    return $self;
}

package FakeContext;

use Carp;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{stash}   = $params{stash}   || {};
    $self->{session} = $params{session} || {};
    $self->{req}     = $params{req};
    $self->{user}    = $params{user};
    $self->{user_ci} = $params{user_ci};
    $self->{username}     = $params{username};
    $self->{model}        = $params{model};
    $self->{config}       = $params{config} || {};
    $self->{authenticate} = $params{authenticate};
    $self->{is_root}      = 0;

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
sub req     { shift->{req} ||= FakeRequest->new }
sub res     { shift->{res} ||= FakeResponse->new }
sub forward { 'FORWARD' }
sub log { FakeLogger->new }
sub logout {}
sub full_logout {}

sub user_ci {
    my $self = shift;
    my ($username) = @_;

    return $self->{user_ci} if $self->{user_ci};

    $username //= $self->username;
    return unless $username;

    ci->user->search_ci( name=>( $username ) );
}

sub is_root { shift->{is_root} }

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
