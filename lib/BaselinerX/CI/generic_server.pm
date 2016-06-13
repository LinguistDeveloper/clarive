package BaselinerX::CI::generic_server;
use Baseliner::Moose;

use Try::Tiny;
use Baseliner::Utils qw(:logging _file _dir _timeout);
use BaselinerX::CI::balix_agent;
use BaselinerX::CI::clax_agent;
use BaselinerX::CI::ftp_agent;
use BaselinerX::CI::ssh_agent;
use BaselinerX::CI::worker_agent;

has connect_ssh    => qw(is rw isa Bool default 1);
has connect_clax   => qw(is rw isa Bool default 1);
has connect_ftp    => qw(is rw isa Bool default 0);
has connect_balix  => qw(is rw isa Bool default 0);
has connect_worker => qw(is rw isa Bool default 0);

with 'Baseliner::Role::CI::Server';

has_ci 'proxy';

sub rel_type { { proxy => [ from_mid => 'server_proxy' ] } }

service 'connect' => {
    name    => 'Test Server Connection',
    form    => '/forms/test_server_connect.js',
    handler => sub {
        my ( $self, $c, $config ) = @_;

        my ($status, $output) = $self->ping;
        _fail( _loc('ERROR: Server is not reachable: %1', $output || 'Unknown error') ) unless $status eq 'OK';

        try {
            my $agent = $self->connect( user => $config->{user} );

            if ( $agent->can('ping') ) {
                $agent->ping;
            }

            _log("OK. Connected.");
        }
        catch {
            my $error = shift;

            _fail _loc("ERROR: Could not connect: %1", $error);
        };

        return 1;
    },
};

sub available_agents { [ 'ssh', 'clax', 'ftp', 'worker', 'balix' ] }

sub error {}
sub rc {}

sub ping {
    my ($self) = @_;

    my $return = 'KO';

    my $out = $self->_ping( $self->hostname );

    my $rc = $? >> 8;
    if ( $rc == 0 ) {
        $return = 'OK';
    }

    return ( $return, $out );
}

method connect( :$user='' ) {
    my $err = '';

    my $agent;
    my @tried_agents;
    foreach my $agent_name (@{ $self->available_agents }) {
        my $connect_method = "connect_$agent_name";

        next unless $self->$connect_method;

        push @tried_agents, $agent_name;

        try {
            $agent = _timeout $self->connect_timeout, sub {
                if ( $self->mid ) {
                    my ($agent) = $self->children( where => { collection => "${agent_name}_agent" } );

                    return $agent if $agent;
                }

                return $self->_build_agent(
                    $agent_name,
                    user    => $user,
                    server  => $self,
                    timeout => $self->agent_timeout,
                    os      => $self->os
                );
            }, _loc( "Agent connection timeout (> %1 sec)", $self->connect_timeout );
        } catch {
            $err .= $_;
        };

        last if $agent;
    }

    if ( !$agent ) {
        if (@tried_agents) {
            _fail _loc( 'ERROR: could not find agent for this server (methods attempted: %1): %2',
                join( ', ', @tried_agents ), $err );
        }
        else {
            _fail _loc('ERROR: no connections configured for this server');
        }
    }

    _debug 'Some connection methods failed: ' . $err if $err;

    return $agent;
}

sub _ping {
    my $self = shift;
    my ($server) = @_;

    return `ping -c 1 "$server" 2>&1`;
}

sub _build_agent {
    my $self = shift;
    my ($agent_name, @params) = @_;

    my $agent_class = 'BaselinerX::CI::' . $agent_name . '_agent';

    return $agent_class->new(@params);
}

1;
