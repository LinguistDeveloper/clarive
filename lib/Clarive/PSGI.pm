package Clarive::PSGI::Web;

use Plack::Builder;
eval {
    require Baseliner;
};
if( $@ ) {
    print "\n\nBaseliner Startup Error:\n";
    print "-------------------------\n";
    print $@;
    print "-------------------------\n\n";
    die $@;
}

{
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

my $app = builder {
    mount '/ws' => $Clarive::MM::app->start;
    mount '/' => Baseliner->psgi_app;
};
