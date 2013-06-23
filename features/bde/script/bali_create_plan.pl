use v5.10;
use strict;
use udpcommon;

my ($username,$project, $state, $view,  @packages) = @ARGV;
my %view_to_bl = ( DESA=>'TEST' );
my $bl = $view_to_bl{ $view } // $view;

=pod 

use Mojo::UserAgent;
my $ua = Mojo::UserAgent->new;

my $tx = $ua->get( 'http://localhost:5000/bde_scan/run' => form =>
        { packages => \@packages, project => $project, username => $username, state => $state, view => $view } );
if ( my $res = $tx->success ) {
    say "===========| " . $res->body . "|============\n";
} else {
    my ( $err, $code ) = $tx->error;
    my $body = $tx->res->body; 
    say '*************ERROR: ' . ( $code ? "$code response: $err: $body" : "Connection error: $err" );
}

=cut

require URI;
require LWP::UserAgent; 
my $ua = LWP::UserAgent->new;
$ua->timeout(200);
$ua->env_proxy;
my %parameters = (
    packages => \@packages, project => $project, username => $username, state => $state, view => $view
);
my $url = URI->new( 'http://localhost:'.$ENV{BASELINER_PORT}.'/bde_scan/run' );
$url->query_form(%parameters);
my $response = $ua->get($url);
if ($response->is_success) {
    say "===========| " . $response->decoded_content . "|============\n";
}
 else {
     my $body =  $response->decoded_content; 
     die '*************ERROR: ' .  $response->status_line . ": $body\n";
}
