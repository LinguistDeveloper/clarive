package BaselinerX::Service::CallWebService;
use Baseliner::Plug;
use Baseliner::Utils;
use Path::Class;
#use Try::Tiny;

with 'Baseliner::Role::Service';

register 'service.web.request' => {
    name => 'Web Request',
    handler => \&web_request,
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
    my $timeout = $config->{timeout};
    my $encoding = $config->{encoding} || 'utf-8';

    if( $encoding ne 'utf-8' ) {
        Encode::from_to($url, 'utf-8', $encoding ) if $url;
        Encode::from_to($args, 'utf-8', $encoding ) if ref $args;
    }

    my $uri = URI->new( $url );
    $uri->query_form( $args );
    my $request = HTTP::Request->new( $method => $uri );
    $request->authorization_basic($config->{username}, $config->{password}) if $config->{username};
    my $ua = LWP::UserAgent->new();
    $ua->timeout( $timeout ) if $timeout;
    for my $k ( keys %$headers ) {
        $ua->default_header( $k => $headers->{$k} );
    }
    $ua->env_proxy;

    my $response = $ua->request( $request );

    _fail sprintf qq/HTTP request failed: %s\nUrl: %s\nArgs: %s/, $response->status_line, $url, _to_json($args)
        unless $response->is_success;
    if( $encoding ne 'utf-8' ) {
        Encode::from_to($response, $encoding, 'utf-8' ) if $response;
    }
    my $content = $response->content;
    return { response=>$response, content=>$content };
} 


1;
