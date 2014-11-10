package Clarive::Pocket;
use strict;
use v5.10;
use Baseliner::Utils qw(:logging);

sub build {
    require Plack::Request;
    require PocketIO;
    _debug('Websockets activated. Building PocketIO handler...');
    my $pocket = PocketIO->new(
        handler => sub {
            my ($self, $env) = @_;
            use Try::Tiny;
            try {
                my $req = Plack::Request->new($env);
                my $sess_id = $req->cookies->{'clarive-session'};
                my $sess = Baseliner->app->get_session_data( "session:$sess_id" ); 
                _debug( _loc('NEW SOCKET ID=%1, USER=%2, SESSION=%3', $self->id,$sess->{username}//'?', $sess_id) );
                $self->on(
                    'echo' => sub {
                        my ($self, $msg, $cb ) = @_;
                        _log( "ECHO: " . $$msg{msg} );
                        $cb->({ rc=>\1, msg=> 'hello '. $$msg{msg} });
                    }
                );
            } catch {
                my $err = shift;
                _error( "ERROR in socket: " . $err );
            };
        }
    );
    _debug('PocketIO handler is ready.');
    return $pocket;
}

1;
