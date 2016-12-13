package BaselinerX::Service::RestRequest;
use Moose;

with 'Baseliner::Role::Service';

use URI::Escape qw(uri_escape_utf8);
use BaselinerX::UA;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils qw(_locl _loc);

register 'service.web.rest' => {
    name        => _locl('REST Request'),
    handler     => \&rest_request,
    job_service => 1,
    icon        => '/static/images/icons/webservice.svg',
    form        => '/forms/rest_request.js',
};

sub rest_request {
    my ( $self, $c, $config ) = @_;

    my $method          = $config->{method} // 'GET';
    my $url             = $config->{url};
    my $args            = $config->{args} // {};
    my $headers         = $config->{headers} || {};
    my $body            = $config->{body} || '';
    my $username        = $config->{username} // '';
    my $password        = $config->{password} // '';
    my $timeout         = $config->{timeout};
    my $accept_any_cert = $config->{accept_any_cert};
    my $auto_parse      = $config->{auto_parse};
    my $errors          = $config->{errors};

    my $ua = $self->_build_ua(
        username   => $username,
        password   => $password,
        verify_SSL => !$accept_any_cert,
        auto_parse => $auto_parse,
        timeout    => $timeout,
        errors     => $errors
    );

    if ( !length $body && %$args ) {
        $headers->{'content-type'} = 'application/x-www-form-urlencoded';
        $body = join '&', map { uri_escape_utf8($_) . '=' . uri_escape_utf8( $args->{$_} ) } sort keys %$args;
    }

    return $ua->request( $method, $url, { headers => $headers, content => $body } );
}

sub _build_ua {
    my $self = shift;
    my (%params) = @_;

    return BaselinerX::UA->new(%params);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
