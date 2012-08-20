use HTTP::Request;
use LWP::UserAgent;
use URI;
use JSON::Any;

my $url  = 'http://localhost:'.$ENV{BASELINER_PORT}.'/sqa/job_approve';
my $args = { project=>shift @ARGV, bl=> shift @ARGV, nature=>shift @ARGV, subproject=>shift @ARGV };
#{ project=>$CAM, subproject=>$_, nature=>$naturaleza, bl=>$EstadoEntorno{$PrevStateName}, value=>'block_deployment' }
my $uri  = URI->new($url);
$uri->query_form($args);
my $request = HTTP::Request->new( GET => $uri, );
my $ua = LWP::UserAgent->new();
#$ua->env_proxy;

my $response = $ua->request($request);

die sprintf qq/HTTP request failed: %s/, $response->status_line
      unless $response->is_success;

my $content = $response->content;
#warn $content;
my $json    = JSON::Any->new();
my $answer = $json->decode($content);
print $content;