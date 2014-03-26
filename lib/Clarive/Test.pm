package Clarive::Test;
{
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
    return Clarive::Test::Agent->new( _ag => $ag );
}

sub URL($) {
	return join '/', $base_url, @_;
}
}

{
    package Clarive::Test::Agent;
    use Mouse;
    use Baseliner::Utils ();
    require WWW::Mechanize;
    has _ag => qw(is rw isa WWW::Mechanize required 1), handles=>qr/.*/;
    
    sub json {
        my ($self,$url,$data) = @_;
        my $req = HTTP::Request->new(POST => $url );
        $req->content_type('application/json');
        $req->content( Util->_encode_json($data));
        $self->request( $req );
        return Util->_decode_json( $self->content );
    }
}

1;
