package Clarive::Test;
use strict;
use warnings;
use v5.10;
use Exporter::Tidy default => [qw(URL)];

our $base_url = '';
our $user = '';
our $password = '';
our $ag;

sub user_agent {
    return $ag if ref $ag;
    $ag = WWW::Mechanize->new();
    $ag->cookie_jar(HTTP::Cookies->new());
    #$ag->agent_alias( 'Chrome 16' );  #te
    my $url = join '/', $base_url, 'login';
    $ag->post( $url, { login=>$user, password=>$password } );
    return $ag;
}

sub URL {
	return join '/', $base_url, @_;
}

1;
