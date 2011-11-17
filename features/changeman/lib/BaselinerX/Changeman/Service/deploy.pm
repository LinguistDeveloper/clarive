package BaselinerX::Changeman::Service::deploy;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use BaselinerX::Dist::Utils;
use BaselinerX::Comm::Balix;
use Data::Dumper;
use Try::Tiny;

with 'Baseliner::Role::Service';

register 'service.changeman.deploy' => {
  name    => 'Execute job in changeman',
  config  => 'config.changeman.connection',
  handler => \&main
};

register 'service.changeman.finalize' => {
  name    => 'Finish job in changeman',
  config  => 'config.changeman.connection',
  handler => \&finalize
};

sub main {
    my ($self, $c, $config) = @_;
    my $job       = $c->stash->{job};
    my $log       = $job->logger;
    my $job_stash = $job->job_stash;
    my $contents  = $job_stash->{ contents };
    my $bl        = $job->job_data->{bl};

    # my $runner = BaselinerX::Job::Service::Runner->new_from_id( jobid=>$job->jobid, same_exec=>1, exec=>'last', silent=>1 );
    # my $jobRow=bali_rs('Job')->search( {id=>$job->jobid} )->first;
    # $runner->{job_row} = $jobRow;
    # $runner->{job_data} = $jobRow->{_column_data};

    $self->execute({config=>$config, job=>$job});
    }

sub execute {
    my ($self, $p) = @_;
    my $config     = $p->{config};
    my $job        = $p->{job};
    my $log        = $job->logger;
    my $stash      = Baseliner->model('Baseliner::BaliJobStash')->find( {id_job=>$job->jobid} );
    my $job_stash  =_load ($stash->stash);
    my $isCHM=undef;

    my $chm = BaselinerX::Changeman->new( host=>$config->{host}, port=>$config->{port}, key=>$config->{key} );
    foreach my $package (_array $job_stash->{contents}) {
        my ($provider, $pkgName) = ($1,$2) if $package->{item} =~ m{(.*)/(.*)};
        next if $provider ne "changeman.package";
        $isCHM=1;
        if ($package->{returncode}) {
            _throw ('Error during changeman execution') if ($package->{returncode} ne 'ok');
        } else {
            my $ret = $chm->xml_runPackageInJob( job=>$job->{name}, package=>$pkgName, job_type=>$job->{job_data}->{type} =~ m{PROMOTE}i?'P':'M', bl=>$job->{job_data}->{bl} eq 'ANTE'?'PREP':$job->{job_data}->{bl} );

            if ($ret->{ReturnCode} ne '00') {
                $log->error (_loc("Can't execute changeman package %1", $package->{item}), _dump $ret);
                _throw ('Error during changeman execution');
            } else {
                $log->info(_loc("Execution for changeman package %1 correctly submitted", $package->{item}), _dump $ret);
                $job->suspend (status=>'WAITING', message=>_loc("Waiting for JES spool outputs"));
                return 0;
                }
            }
        }

    ## En PROD si el pase tiene activo el refresco de Linklist realizar la llamada al rexx de refresco.
    if ($job->{job_data}->{bl} && (join",", _array $job_stash->{job_options}) =~ m{chm_rf_ll}) {
        my @sites=map{ $_->{data}->{site}=~s{ }{}; split /,/,$_->{data}->{site} } _array $job_stash->{contents};
        _log qq{my ret = chm->xml_refreshLLA(join (', ',@sites))};
        my $ret = $chm->xml_refreshLLA(join (', ',@sites));
         
        if ($ret->{ReturnCode} ne '00') {
            $log->error (_loc("Can't execute Linklist refresh"), $ret->{Message});
            _throw ('Error during changeman execution');
        } else {
            $log->info(_loc("Linklist refresh correctly submitted"));
            }
        }
    if ($isCHM) {
        my @pkgs;
        Baseliner->model('Jobs')->resume(id=>$job->jobid);   ## Continuamos con el pase SCM
        foreach my $package (_array $job_stash->{contents}) {  ## Desasociamos los paquetes del pase.
            my ($provider, $pkgName) = ($1,$2) if $package->{item} =~ m{(.*)/(.*)};
            push @pkgs, $pkgName if $provider eq "changeman.package";
            }
        my $ret= $chm->xml_cancelJob(job=>$job->{name}, items=>@pkgs) ;
        }
    }

sub finalize {
    my ($self, $p) = @_;
    my $runner     = $p->{runner};
    my $pkg        = $p->{pkg};
    my $rc         = $p->{rc};
    my $config     = Baseliner->model('ConfigStore')->get( 'config.changeman.connection' );

    my $stash = Baseliner->model('Baseliner::BaliJobStash')->find( {id_job=>$runner->jobid} );
    my $job_stash=_load ($stash->stash);
    foreach my $package (_array $job_stash->{contents}) {
       next if $package->{item} !~ m{$pkg$};
       $package->{returncode}=$rc;
       }

    $stash->stash(_dump $job_stash);
    $stash->update();
    $self->execute({config=>$config, job=>$runner});
    }
1
