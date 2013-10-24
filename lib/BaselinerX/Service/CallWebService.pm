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
    
    my $method = $config->{method} // 'GET';
    my $url    = $config->{url};
    my $args   = $config->{args};

    my $uri = URI->new( $url );
    $uri->query_form( $args );
    my $request = HTTP::Request->new( $method => $uri );
    $request->authorization_basic($config->{username}, $config->{password}) if $config->{username};
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy;

    my $response = $ua->request( $request );

    _fail sprintf qq/HTTP request failed: %s\nUrl: %s\nArgs: %s/, $response->status_line, $url, _to_json($args)
        unless $response->is_success;
    my $content = $response->content;
    return { response=>$response, content=>$content };
} 


# deprecated?
register 'service.call_webservice' => {
    name => 'Calls a webservice',
    icon => '/static/images/icons/webservice.png',
    handler => \&_call_ws,
    data => { url => '', username => '', password => '', args => { id => '', format => ''} }
};

sub _call_ws {
    my ( $self, $c, $data ) = @_;

    _error $data;

    my $url  = $data->{url};

    my $args = $data->{args};

    my $uri = URI->new( $url );
    $uri->query_form( $args );
    my $request = HTTP::Request->new( GET => $uri );
    $request->authorization_basic($data->{username}, $data->{password}) if $data->{username};
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy;

    my $response = $ua->request( $request );

    die sprintf qq/HTTP request failed: %s\nUrl: %s\nArgs: %s/, $response->status_line, $url, _dump $args
        unless $response->is_success;

    my $content = $response->content;

    return { data => $content };
} ## end sub _call_ws

1;
