package BaselinerX::Job::Service::JobFormInfo;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use LWP::UserAgent;

with 'Baseliner::Role::Service';

register 'service.job.form.info' => {name    => 'Returns form data for the current job in HTML format.',
                                     handler => \&main};

sub main {
  my ($self, $c, $config) = @_;
  my $job      = $c->stash->{job};
  my $log      = $job->logger;
  my $elements = $job->job_stash->{elements}->{elements};
  my @cams     = _unique map { _pathxs $_->{fullpath}, 1 } @{$elements};
  for my $cam (@cams) {
    my $url = do {
      my $env    = (substr $job->job_data->{bl}, 0, 1);
      my $server = _bde_conf 'scminfreal';
      "$server/inf/infFormIPrint.jsp?CAM=${cam}&ENV=$env";
    };
    my $ua = new LWP::UserAgent;
    $ua->cookie_jar({});
    $log->debug("Conectando a '$url' para obtener el informe de infraestructura...");
    my $req = HTTP::Request->new(GET => $url);
    $req->header("iv-user" => (_bde_conf 'whoami'));
    my $resp = $ua->request($req)->content;
    $log->info("Infraestructura de la aplicacion $cam", $resp);
  }
  return;
}

1;
