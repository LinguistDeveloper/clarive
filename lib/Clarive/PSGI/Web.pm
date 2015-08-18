package Clarive::PSGI::Web;
use Plack::Builder;
use strict;
use warnings;

our $PP = $$;

eval {
    require Baseliner;
    Baseliner->build_app();
};

if( $@ ) {
    print "\n\nBaseliner Startup Error:\n";
    print "-------------------------\n";
    print $@;
    print "-------------------------\n\n";
    die $@;
}

builder {
    # socketio
    if( Clarive->opts->{'websockets'} ) {
        require Clarive::Pocket;
        mount '/socket.io' => Clarive::Pocket->build;
    } else {
        mount '/socket.io' => sub{ 
            # avoids 401 errors TODO consider sending something that deactivates socketio clients
        }; 
    }
    #mount '/' => sub { [ 0, ["Content-Type","text/html"], ["Hello=$PP"] ]; };
    mount '/check_status' => sub {
        my $p = shift;
        my $q = $p->{QUERY_STRING};
        my $user = ci->user->search_ci( name => 'root' );
        if( $user ) {
            [ 200, ["Content-Type","text/html"], ["Clarive: ok"] ];
        } else {
            [ 401, ["Content-Type","text/html"], ["Clarive: no auth"] ];
        }
    };
    mount '/' => Baseliner->psgi_app;
};
