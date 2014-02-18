package Clarive::Test;
use strict;
use warnings;
use v5.10;

our $base_url = '';
our $user = '';
our $password = '';

sub user_agent {
    my $ag = WWW::Mechanize->new();
    $ag->cookie_jar(HTTP::Cookies->new());
    #$ag->agent_alias( 'Chrome 16' );  #te
    my $url = join '/', $base_url, 'login';
    $ag->post( $url, { login=>$user, password=>$password } );
    return $ag;
}

1;
