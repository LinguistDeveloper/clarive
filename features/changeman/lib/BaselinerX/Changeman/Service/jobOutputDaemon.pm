package BaselinerX::Changeman::Service::jobOutputDaemon;
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

register 'service.changeman.jobOutputDaemon' => {
  name    => 'Get Job output from MVS',
  config  => 'config.changeman.connection',
  handler => \&run
};

sub run {
    my ( $self, $c, $config ) = @_;
    _log 'JES spool daemon starting.';
    
    my $frequency = $config->{frequency};
    my $iterations = $config->{iterations};
    my $bx = BaselinerX::Comm::Balix->new(os=>"mvs", host=>$config->{host}, port=>$config->{port}, key=>$config->{key});
    
    for( 1..$iterations ) {
        $self->run_once( $c, $config, $bx );
        sleep $frequency;
    }
    _log 'JES spool daemon stopping.';
}

sub run_once {
    my ($self, $c, $config, $bx) = @_;
    my $workDir=$config->{workdir};
    my $jobConfig = Baseliner->model('ConfigStore')->get( 'config.job' );

    my $case = $c->config->{user_case};

    my ($RC, $RET, $isSCM) = (undef,undef,undef);
    my %finishedJOBS;

	# Controlamos que balix se mantiene conectado

	try {
		local $SIG{ALRM} = sub { die "alarm\n" };
        alarm 60;
		($RC, $RET)=$bx->execute(qq{whoami});
		alarm 0;
	} catch {
		_log 'USS connection timeout';
		$bx = BaselinerX::Comm::Balix->new(os=>"mvs", host=>$config->{host}, port=>$config->{port}, key=>$config->{key});
		($RC, $RET)=$bx->execute(qq{whoami});
		if ( $RC ne 0 ) {
			die "Could not connect to USS.  Exiting"
		}
	};
	
    ($RC, $RET)=$bx->execute(qq{tsocmd "LISTCAT LEVEL('CHM.PSCM.P')" | /bin/grep NONVSAM | /bin/cut -d' ' -f3});

    foreach my $pds (split /\n/,$RET) {
        my ($jobId, $job, $oldJob, $jobName, $runner, $relation, $row, $username) = (undef, undef, undef, undef, undef, undef, undef);
        next if $pds =~ m{LISTCAT LEVEL};
        $isSCM=undef;
        my @pase=split /\./, $pds;

        # _log "Procesando PDS: $pds";

        $relation=Baseliner->model('Baseliner::BaliRelationship')->find({type=>'Changeman.PDS.to.JobId', from_ns=>$pds});
        $jobId=$relation->to_ns if ref $relation;
        $jobId=$1 if $jobId =~ m{job/(.*)};
        $jobId=$pds =~m{.*\.A(\d{5})\.A(\d{5})\.....$}?"$1$2":undef if ! $jobId;
        $jobId=int($jobId);
        $job = bali_rs('Job')->find( $jobId ) if $jobId;

        $jobName = undef;

        if ($pds =~m{.*\.A(\d{5})\.A(\d{5})\.....$}) {
            $jobName="SCM-$jobId";
            $isSCM=1;
        } else {
            $jobName="CHM-$1$2" if $pds =~m{.*\.F(\d*)\.H(\d*)\.....$};
            $isSCM=undef;
            }

        my $chmPKG=sprintf("%s%06d",$pase[3],int(substr($pase[4],1)));
        my $site=$pase[7];
        my $jobDir=File::Spec->catdir($workDir, $jobName, $site );
        ($RC, $RET)=$bx->execute(qq{mkdir -p "$jobDir"});
        ($RC, $RET)=$bx->execute(qq{cp "//'$pds'" "$jobDir"});
        if ($RC) { ## No se ha podido copiar el dataset, lo intentamos luego...
           # _log "No se ha podido copiar el dataset $pds, lo intentamos luego...\n$RET";
           }

        ($RC, my $FILES)=$bx->execute(qq{ls -t "$jobDir"});

        if (ref $job) {
            $runner = BaselinerX::Job::Service::Runner->new_from_id( jobid=>$job->id, same_exec=>1, exec=>'last', silent=>1 );
            my $jobRow=bali_rs('Job')->search( {id=>$jobId} )->first;
            $runner->{job_row} = $jobRow;
            $runner->{job_data} = $jobRow->{_column_data};
        } else {
            my $bl = $config->{stateMap}{$pase[7]};

            my $type=undef;
            foreach my $fileName (split /\n/,$FILES) {
                if ($fileName =~ m{userid}) {
                    ($RC, $RET)=$bx->execute(qq{find $jobDir -name "userid" -exec cat {} \\;});
                    $username=$1 if ( ! $RC && $RET =~ m{^(\w+).*} );
                    $username= $case eq 'uc' ? uc($username) : ( $case eq 'lc' ) ? lc($username) : $username;
                    }

                if ($fileName=~m{....(1|2|3|8)..} ) {
                    $type=$type||='promote';
                } elsif ($fileName=~m{....(4|5|6|7|9)..} ) {
                    $type=$type||='demote';
                } else {
                    $type=undef unless $type;
                    }
                }
            next if ! $type; ## Slo tenemos el fichero username, no podemos crear pase an...

            try {
                $oldJob = Baseliner->model('Jobs')->is_in_active_job( "changeman.package/$chmPKG" );
            } catch { _log "error $_ en activejobs";};
            if (ref $oldJob && ($oldJob->bl ne $bl || $oldJob->step ne 'RUN' || $oldJob->type ne $type) ) {
                # _log "## Espero a que acabe el job ". $oldJob->id ." en ejecucin";
                next;
                }
            if (! $oldJob ) {
                try {
                    BaselinerX::Changeman::Provider::Package->getPkg($c,{ query=>$chmPKG });
                    my $pkg_data = Baseliner->model('Repository')->get( ns=>"changeman.package/$chmPKG");

                    _throw _loc("Package %1 does not exists in Changeman", $chmPKG) if ref $pkg_data->{user} eq 'HASH';

                    my $status = 'IN-EDIT';
                    my $now = DateTime->now(time_zone=>_tz);
                    my $end = $now->clone->add( hours => 24 );

                    # _debug qq{job = Baseliner->model('Jobs')->create(
                        # starttime    => $now,
                        # schedtime    => $now,
                        # maxstarttime => $end,
                        # status       => $status,
                        # step         => 'RUN',
                        # type         => $type,
                        # runner       => $jobConfig->{runner},
                        # username     => "vtchm",
                        # comments     => $isSCM?_loc("JOB for package $chmPKG created in Baseliner but not Found"):_loc("JOB for package $chmPKG created in Changeman recovered by Baseliner"),
                        # ns           => "changeman.package/$chmPKG",
                        # bl           => $bl,
                        # items        => [} . _dump $pkg_data . qq{]
                        # );
                        # };

                    $job = Baseliner->model('Jobs')->create(
                        starttime    => $now,
                        schedtime    => $now,
                        maxstarttime => $end,
                        status       => $status,
                        step         => 'RUN',
                        type         => $type,
                        runner       => $jobConfig->{runner},
                        username     => $username || _loc('Unknown'),
                        comments     => $isSCM?_loc("JOB for package $chmPKG created in Baseliner but not Found"):_loc("JOB for package $chmPKG created in Changeman recovered by Baseliner"),
                        ns           => "changeman.package/$chmPKG",
                        bl           => $bl,
                        items        => [ $pkg_data ]
                        );

                    $isSCM=undef;
                    $job->status( 'RUNNING' );
                    $job->update;
                    # $job = bali_rs('Job')->find( $jobId );
                } catch {
                    _log (_loc("Can't create job because %1", $_));
                    next;  ## Me salto el PDS
                    };
            } else {
                $job=$oldJob;
            }
            next if ! ref $job;

            $jobId=$job->id;
            Baseliner->model('Baseliner::BaliRelationship')->update_or_create({type=>'Changeman.PDS.to.JobId', from_ns=>$pds, to_ns=>"job/$jobId"});
            $runner = BaselinerX::Job::Service::Runner->new_from_id( jobid=>$jobId, same_exec=>1, exec=>'last', silent=>1 );
            my $jobRow=bali_rs('Job')->search( {id=>$jobId} )->first;
            $runner->{job_row} = $jobRow;
            $runner->{job_data} = $jobRow->{_column_data};
            }
        my $fin=undef;

        foreach my $fileName (split /\n/,$FILES) {
            # _log "Procesando $fileName of $pds";
            my $repeated = Baseliner->model('Baseliner::BaliLogData')->search({id_job=>$jobId, name=>"/$site/$fileName/"})->first;
            next if ref $repeated;
            next if $fileName eq 'userid';

            my $row=$runner->logger->info( _loc('Recovered output for job %1 in PDS %2', $fileName, $pds), more=>'jes' ) if $fileName !~ m{finok|finko|siteok|siteko}i;
            my $fullFileName=File::Spec->catfile($jobDir, $fileName );
            ($RC, my $text)=$bx->execute(qq{cat $fullFileName});

            if ( $fileName =~ m{finok|finko|siteok|siteko}i ){
                $fin={
                    site=>$fileName eq 'siteok'?'ok':$fileName eq 'siteko'?'ko':$fin->{site},
                    job=>$fileName eq 'finok'?'ok':$fileName eq 'finko'?'ko':$fin->{job}
                    };
                next;
                }

            my @RET=split / @==================== /, $text;
            foreach ( @RET ) {
                my ($ddname, $spool)=split / ====================/, $_;
                $ddname=~s{\s*$}{};
                $ddname="/$site/$fileName/$ddname";
                my $logdata=$row->bali_log_datas->create({
                    id_log=>$row->id,
                    data=>$spool,
                    name=>$ddname,
                    type=>'jes',
                    len=>length($spool),
                    id_job=>$jobId
                    });
                }
            }

        if ( $fin->{site} ) {
            my $repeated = Baseliner->model('Baseliner::BaliLogData')->search({id_job=>$jobId, name=>"/$site/site".$fin->{site}})->first;
            if (! ref $repeated) {
                if ($fin->{site} eq 'ok') {
                    $row=$runner->logger->info( _loc('Changeman job for package %1 in site %2 finished successfully', $chmPKG, $site) );
                } elsif ($fin->{site} eq 'ko' ) {
                    $row=$runner->logger->error( _loc('Changeman job for package %1 in site %2 finished with error', $chmPKG, $site) );
                    }

                my $logdata=$row->bali_log_datas->create({
                    id_log=>$row->id,
                    data=>$fin->{site},
                    name=>"/$site/site".$fin->{site},
                    type=>'jes',
                    len=>0,
                    id_job=>$jobId
                    });
                }
            }

        if ( $fin->{job} ) {
            # _log "Encontrado $fin->{job} para $chmPKG";
            $finishedJOBS{$jobId}= {
                job=>$job,
                jobid=>$jobId,
                status=>$fin->{job},
                chmpkg=>$chmPKG,
                isscm=>$isSCM,
                pds=>$pds
                };
            }

        if ( $fin->{site} || $fin->{job} ) {
            if ($config->{clean} eq 'RENAME') {
                my $pdsProcessed=$pds;
                $pdsProcessed=~s{\.P\.}{\.T\.}g;
                ($RC, $RET)=$bx->execute(qq{tsocmd "RENAME $pds $pdsProcessed"});
            } elsif ($config->{clean} eq 'DELETE') {
                ($RC, $RET)=$bx->execute(qq{tsocmd "DELETE $pds"});
                }

            }

        $jobDir=File::Spec->catdir($workDir, $jobName );
        ($RC, $RET)=$bx->execute(qq{rm -rf $jobDir});
        }

    my ($row, $runner) = (undef,undef);
    foreach ( keys %finishedJOBS ) {
        my $job=$finishedJOBS{$_}->{job};
        my $jobId=$finishedJOBS{$_}->{jobid};
        my $status=$finishedJOBS{$_}->{status};
        my $chmPKG=$finishedJOBS{$_}->{chmpkg};
        my $isSCM=$finishedJOBS{$_}->{isscm};
        my $pds=$finishedJOBS{$_}->{pds};

        my $repeated = Baseliner->model('Baseliner::BaliLogData')->search({ id_job=>$jobId, name=>"/fin".$status })->first;
        if (! ref $repeated) {
            $runner = BaselinerX::Job::Service::Runner->new_from_id( jobid=>$jobId, same_exec=>1, exec=>'last', silent=>1 );
            my $jobRow=bali_rs('Job')->search( {id=>$jobId} )->first;
            $runner->{job_row} = $jobRow;
            $runner->{job_data} = $jobRow->{_column_data};

            if ( $status eq 'ok' ) {
                $row=$runner->logger->info( _loc('Changeman job for package %1 finished successfully', $chmPKG) );
                $job->status( 'READY' );
            } elsif ( $status eq 'ko' ) {
                $row=$runner->logger->error( _loc('Changeman job for package %1 finished with error', $chmPKG) );
                $job->status( 'ERROR' );
                }

            my $logdata=$row->bali_log_datas->create({
                id_log=>$row->id,
                data=>$status,
                name=>"/fin".$status,
                type=>'jes',
                len=>0,
                id_job=>$jobId
                });
            if ($isSCM) {
                BaselinerX::Changeman::Service::deploy->finalize ({runner=>$runner, pkg=>$chmPKG, rc=>$status})
            } else {
                my $relation=Baseliner->model('Baseliner::BaliRelationship')->find({type=>'Changeman.PDS.to.JobId', to_ns=>"job/$jobId"});
                ref $relation && $relation->delete;
                $job->step( 'POST' );
                $job->update;
                }
            }
        }
    return;
    }

1;
