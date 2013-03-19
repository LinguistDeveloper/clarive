package BaselinerX::Changeman::Service::getStatus;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use BaselinerX::Dist::Utils;
use BaselinerX::Comm::Balix;
use BaselinerX::Changeman;
use Data::Dumper;
use Try::Tiny;

with 'Baseliner::Role::Service';

register 'service.changeman.getStatus' => {
  name   => 'Test if running jobs are already running',
  config  => 'config.changeman.connection',
  handler => \&main
};

sub main {
    my ($self, $c, $config) = @_;

    my @jobs = DB->BaliJob->search({ status => {-in => [qw/WAITING SITEERROR/] } })->all;
JOB:foreach my $job (@jobs) {
        my $job_stash = _load $job->stash;
        my $contents  = $job_stash->{ contents };
        my $bl        = $job->bl;
PKG:    foreach my $content (_array $contents) {
            next PKG if $content->{provider} ne 'namespace.changeman.package';
            my $chm = BaselinerX::Changeman->new( host=>'prue' );
            my $package=(ns_split($content->{item}))[1];
            my $jobType=$job->type eq 'promote'?'p':'m';
            my $chmData=$chm->xml_getStatus(package=>$package, job_type=>$jobType, to=>$job->bl) ;
            next PKG if $chmData->{vivo};
            $job->status('MUST_DIE');
            $job->update;
            next JOB;      
        }
    }
}

1
