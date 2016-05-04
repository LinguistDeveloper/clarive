package Clarive::Code::JSModules::web;
use strict;
use warnings;

use Clarive::Code::JSUtils;

sub generate {
    my $class = shift;
    my $stash = shift;
    my $js = shift;

    +{
        agent => js_sub {
            my $opts = shift;

            require LWP::UserAgent;

            my $ua = LWP::UserAgent->new( agent=>'clarive/js', %{ $opts || {} } );

            # rgo: map_instance does not work for $ua
            return {
                request       => js_sub { $ua->request(@_) },
                get           => js_sub { _map_instance( $ua->get(@_) ) },
                head          => js_sub { _map_instance( $ua->head(@_) ) },
                post          => js_sub { _map_instance( $ua->post(@_) ) },
                put           => js_sub { _map_instance( $ua->put(@_) ) },
                delete        => js_sub { _map_instance( $ua->delete(@_) ) },
                mirror        => js_sub { _map_instance( $ua->mirror(@_) ) },
                simpleRequest => js_sub { _map_instance( $ua->simple_request(@_) ) },
                isOnline      => js_sub { $ua->is_online(@_) },
                isProtocolSupported => js_sub { $ua->is_protocol_supported(@_) },
            }
        },
        request => js_sub {
            my ($method, $endpoint, $opts) = @_;

            require HTTP::Request::Common;

            my $req = HTTP::Request->new( $method => $endpoint, %{ $opts || {} } );

            return $req;
        },
    };
}

1;
