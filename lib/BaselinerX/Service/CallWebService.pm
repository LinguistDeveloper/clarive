package BaselinerX::Service::CallWebService;
use Baseliner::Plug;
use Baseliner::Utils;
use Path::Class;
#use Try::Tiny;

with 'Baseliner::Role::Service';

register 'service.web.request' => {
    name => 'Web Request',
    handler => \&web_request,
    job_service  => 1,
    icon => '/static/images/icons/webservice.png',
    form => '/forms/web_request.js', 
};

sub web_request {
    my ( $self, $c, $config ) = @_;

    require LWP::UserAgent;
    require HTTP::Request;
    require Encode;
    
    my $method = $config->{method} // 'GET';
    my $url    = $config->{url};
    my $args   = $config->{args};
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
    my $ua = LWP::UserAgent->new();
    if($accept_any_cert){
        $ua->ssl_opts( verify_hostname => 0 );
    }
    $ua->timeout( $timeout ) if $timeout;
    for my $k ( keys %$headers ) {
        $ua->default_header( $k => $headers->{$k} );
    }
    $ua->env_proxy;
    
    if( length $body ) {
        $request->content( $body ); 
    }

    my $response = $ua->request( $request );

    _fail sprintf qq/HTTP request failed: %s\nUrl: %s\nArgs: %s/, $response->status_line, $url, _to_json($args)
        unless $response->is_success;
    my $content = $response->decoded_content;
        #if( $encoding ne 'utf-8' ) {
        #Encode::from_to($content, $encoding, 'utf-8' ) if $content;
        #}
    return { response=>$response, content=>$content };
} 


1;
