package Clarive::PSGI::Web;
use Plack::Builder;

our $PP = $$;

eval {
    #warn ">>>>>>>>>>>>>>RELOADING";
    require Baseliner;
};
if( $@ ) {
    print "\n\nBaseliner Startup Error:\n";
    print "-------------------------\n";
    print $@;
    print "-------------------------\n\n";
    die $@;
}

if(0) {
    package Clarive::MM;
    use strict;
    use Mojo::Base 'Mojolicious';
    #use Mojo::UserAgent;
    our $app = __PACKAGE__->new;
    my $routes = $app->routes->namespaces([]);
    my $clients = {};

    $routes->any( '/' => sub {
        my $self = shift;
        $self->render_json({ aa=>22 });
    });
    $routes->websocket( '/connect' => sub {
        my $self = shift;
        $app->log->debug(sprintf '***** Client connected: %s', $self->tx);
        Mojo::IOLoop->stream($self->tx->connection)->timeout(300);  # 5 minutes
        my $id = sprintf "%s", $self->tx;
        $clients->{$id} = $self->tx;
    });
}

builder {
    #mount '/ws' => $Clarive::MM::app->start;
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
