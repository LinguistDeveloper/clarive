package Clarive::Code::JSModules::ws;
use strict;
use warnings;

use Clarive::Code::JSUtils;

sub generate {
    my $class = shift;
    my $stash = shift;
    my $js = shift;

    +{
        request => js_sub {
            return {
                url => js_sub {
                    my $header = shift;
                    return $stash->{WSURL};
                },
                body => js_sub {
                    my $header = shift;
                    return $stash->{ws_body};
                },
                args => js_sub {
                    return $stash->{ws_arguments} || [];
                },
                headers => js_sub {
                    my $header = shift;
                    return length $header
                        ? $stash->{ws_headers}{$header}
                        : $stash->{ws_headers}
                },
                params => js_sub {
                    my $param = shift;
                    return length $param
                        ? $stash->{ws_params}{$param}
                        : $stash->{ws_params}
                }
            }
        },
        response => js_sub {
            return {
                body => js_sub { $stash->{ws_response} = shift },
                cookies => js_sub { $stash->{ws_response_methods}{cookies} = shift },
                status => js_sub { $stash->{ws_response_methods}{status} = shift },
                redirect => js_sub { $stash->{ws_response_methods}{redirect} = shift },
                location => js_sub { $stash->{ws_response_methods}{location} = shift },
                write => js_sub { $stash->{ws_response_methods}{write} = shift },
                content_type => js_sub { $stash->{ws_response_methods}{content_type} = shift },
                headers => js_sub { $stash->{ws_response_methods}{headers} = shift },
                header => js_sub { $stash->{ws_response_methods}{header} = shift },
                get => js_sub {
                    $stash->{ws_response} //= {};
                },
                data => js_sub {
                    my ($key,$value) = @_;
                    $stash->{ws_response}{$key} = $value;
                }
            }
        }
    };
}

1;
