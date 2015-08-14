package BaselinerX::CI::script;
use Baseliner::Moose;
use Baseliner::Utils qw(_array _loc _fail _log _debug);

has path => qw(is rw isa Str required 1);
has args => qw(is rw isa Any);
has_cis 'server';
has_cis 'agent';

with 'Baseliner::Role::CI::Script';

sub rel_type {
    {
        server  => [ from_mid => 'script_server' ],
        agent   => [ from_mid => 'script_agent' ],
    };
}

service 'run_script' => {
    name    => _loc('Run Script'),
    form    => '/forms/test_server_connect.js',
    icon    => '/static/images/icons/cog_java.png',
    #icon    => '/static/images/icons/script.png',
    handler => sub {
        my ($self,$c,$config) = @_;
        my @output = $self->run( user=>$config->{user} );
        _log($_) for @output;
        \@output;
    }
};

method run( :$user='' ) {
    my $servers = $self->server;
    my @output;
    _fail _loc 'Missing attribute `path`' unless length $self->path;
    if( my @agents = _array( $self->agent ) ) {
        _debug( 'Running agent...' );
        for my $ag ( @agents ) {
            $ag->throw_errors(1);
            $ag->execute( $self->path, _array( $self->args ) );
            push @output, $ag->tuple_str;
        }
    }
    else {
        _fail _loc 'Missing parameter `user`' unless length $user;
        for my $server ( _array( $servers ) ) {
            my $ag = $server->connect( user=>$user );
            $ag->throw_errors(1);
            $ag->execute( $self->path, _array( $self->args ) );
            push @output, $ag->tuple_str;
        }
    }
    return @output;
}

sub error {}

sub ping {'OK'};

1;
