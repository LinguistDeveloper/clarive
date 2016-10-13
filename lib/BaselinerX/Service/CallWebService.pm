package BaselinerX::Service::CallWebService;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Path::Class;
#use Try::Tiny;

use URI;
use LWP::UserAgent;
use HTTP::Request;
use Encode ();

with 'Baseliner::Role::Service';

register 'service.web.request' => {
    name => 'Web Request',
    handler => \&web_request,
    job_service  => 1,
    icon => '/static/images/icons/webservice.svg',
    form => '/forms/web_request.js',
};

sub web_request {
    my ( $self, $c, $config ) = @_;

    my $method = $config->{method} // 'GET';
    my $url    = $config->{url};
    my $args   = $config->{args} // {};
    my $headers = $config->{headers} || {};
    my $body = $config->{body} || '';
    my $timeout = $config->{timeout};
    my $encoding = $config->{encoding} || 'utf-8';
    my $accept_any_cert = $config->{accept_any_cert};

    if( $encoding ne 'utf-8' ) {
        Encode::from_to($url, 'utf-8', $encoding ) if $url;
        if( ref $args ) {
            my $x = _dump($args);
            Encode::from_to( $x, 'utf-8', $encoding );
            $args = _load( $x );
        }
        if( ref $headers ) {
            my $x = _dump($headers);
            Encode::from_to( $x, 'utf-8', $encoding );
            $headers = _load( $x );
        }
    }

    my $uri = URI->new( $url );
    $uri->query_form( $args );
    my $request = HTTP::Request->new( $method => $uri );
    $request->authorization_basic($config->{username}, $config->{password}) if $config->{username};
    my $ua = $self->_build_ua();
    if($accept_any_cert){
        $ua->ssl_opts( verify_hostname => 0 );
    }
    $ua->timeout( $timeout ) if $timeout;
    for my $k ( keys %$headers ) {
        $ua->default_header( $k => $headers->{$k} );
    }
    $ua->env_proxy;

    if ( length $body ) {
        $request->content( Encode::encode( 'UTF-8', $body ) );
    }

    my $response = $ua->request( $request );

    $c->stash->{_ws_code} = $response->code;
    $c->stash->{_ws_body} = $response->decoded_content;

    if( ! $response->is_success ) {
        _error( $response->decoded_content );
        _fail sprintf qq/HTTP request failed: %s\nUrl: %s\nArgs: %s/, $response->status_line, $url, _to_json($args);
    }
    my $content = $response->decoded_content;
        #if( $encoding ne 'utf-8' ) {
        #Encode::from_to($content, $encoding, 'utf-8' ) if $content;
        #}
    return { response=>$response, content=>$content };
}

sub _build_ua {
    my $self = shift;

    return LWP::UserAgent->new();
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
