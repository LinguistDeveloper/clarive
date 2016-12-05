package BaselinerX::UA;
use strict;
use warnings;
use parent 'HTTP::Tiny';

no warnings 'redefine';

use URI         ();
use Encode      ();
use XML::Simple ();
use Baseliner::Utils qw(_fail _error _truncate _decode_json);

sub new {
    my $class = shift;
    my (%params) = @_;

    $params{verify_SSL} //= 1;

    if ( defined $params{timeout} ) {
        if ( length $params{timeout} ) {
            $params{timeout} = undef if !$params{timeout};
        }
        else {
            delete $params{timeout};
        }
    }

    my $username = delete $params{username};
    my $password = delete $params{password};

    my $errors     = delete $params{errors}     // 'fail';
    my $auto_parse = delete $params{auto_parse} // 1;

    my $timeout_attempts    = delete $params{timeout_attempts}    // 1;
    my $connection_attempts = delete $params{connection_attempts} // 1;

    my $log_request_cb  = delete $params{log_request_cb};
    my $log_response_cb = delete $params{log_response_cb};

    my $self = $class->SUPER::new(%params);

    $self->{username} = $username;
    $self->{password} = $password;

    $self->{errors}     = $errors;
    $self->{auto_parse} = $auto_parse;

    $self->{timeout_attempts}    = $timeout_attempts;
    $self->{connection_attempts} = $connection_attempts;

    $self->{log_request_cb}  = $log_request_cb;
    $self->{log_response_cb} = $log_response_cb;

    return $self;
}

sub _agent { 'ClariveUA/' . ( $Clarive::VERSION // '' ) }

sub request {
    my $self = shift;
    my ( $method, $url, $options ) = @_;

    $url = URI->new($url);

    if ( $self->{username} ) {
        $url->userinfo("$self->{username}:$self->{password}");
    }

    if ( defined $options->{content} ) {
        $options->{content} = Encode::encode( 'UTF-8', $options->{content} );
    }

    my $response;

    my $timeout_attempts    = 0;
    my $connection_attempts = 0;

    {
        do {
            $response = $self->SUPER::request( $method, "$url", $options );

            if ( $response->{status} eq '599' && $response->{reason} eq 'Internal Exception' ) {
                my $content = $response->{content} // '';
                if ( $content =~ m/(?:timeout|timed\s*out)/i ) {
                    $timeout_attempts++;
                    $response->{_timeout_attempts} = $timeout_attempts;
                }
                elsif ( $content =~ m/(?:could not connect|refused|closed)/i ) {
                    $connection_attempts++;
                    $response->{_connection_attempts} = $connection_attempts;
                }
                else {
                    last;
                }
            }
            else {
                last;
            }
          } while ( $timeout_attempts < $self->{timeout_attempts}
            && $connection_attempts < $self->{connection_attempts} );
    }

    if ( !$response->{success} ) {
        my $request_raw = "$method $url\n";
        $request_raw .= join "\n", map { "$_: $options->{headers}->{$_}" } sort keys %{ $options->{headers} || {} };
        if ( defined $options->{content} ) {
            $request_raw .= "\n\n" . _truncate $options->{content} // '', 255;
        }

        my $response_raw = "$response->{status} $response->{reason}\n";
        $response_raw .= join "\n", map { "$_: $response->{headers}->{$_}" } sort keys %{ $response->{headers} || {} };
        $response_raw .= "\n\n" . _truncate $response->{content} // '', 255;

        my $error = sprintf qq/HTTP request failed:\n>>>\n%s\n<<<\n%s/, $request_raw, $response_raw;

        if ( $self->{errors} eq 'fail' ) {
            _fail $error;
        }
        elsif ( $self->{errors} eq 'warn' ) {
            _error($error);
        }
    }

    if ( $self->{auto_parse} ) {
        my $content_type = $response->{headers}->{'content-type'};

        if ($content_type) {
            if ( $content_type =~ m/json/ ) {
                $response->{content} = _decode_json $response->{content};
            }
            elsif ( $content_type =~ m/xml/ ) {
                my $xs = XML::Simple->new();

                $response->{content} = $xs->XMLin( \$response->{content} );
            }
        }
    }

    return $response;
}

sub _log_request {
    my $self = shift;
    my ($request) = @_;

    $self->{log_request_cb}->( $self, $request ) if $self->{log_request_cb};
}

sub _log_response {
    my $self = shift;
    my ($response) = @_;

    $self->{log_response_cb}->( $self, $response ) if $self->{log_response_cb};
}

1;
