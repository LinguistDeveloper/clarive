package BaselinerX::Changeman::Service::jobDaemon;
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

register 'service.changeman.jobDaemon' => {
  name    => 'Get Job output from MVS',
  config  => 'config.changeman.log_connection',
  handler => \&run
};

register 'service.changeman.file_scan' => {
  name    => 'Get Job output from MVS',
  config  => 'config.changeman.log_connection',
  handler => \&file_scan
};

register 'config.changeman.log_connection' => {
   name => 'Changeman Connection to Recover Logs',
   metadata => [
      { id=>'host', label=>'Changeman Log Host', type=>'text', default=>'prusv063' },
      { id=>'port', label=>'Changeman Log Port', type=>'text', default=>'58765' },
      { id=>'key', label=>'Changeman Log Key', type=>'text', default=>'Si5JVWprYWRsYWooKCUzMi4rODdmai4uMTklZCQpM2RmbrfnZWG3anNhMTE6OTgsMUBqaHUoaGhIdDJqRXE=' },
      { id=>'user', label=>'Changeman functional user', type=>'text', default=>'vpchm01' },
      { id=>'logPath', label=>'Changeman Logdir', type=>'text', default=>'/tmp/CHMT' },
      { id=>'pattern', label=>'Changeman pattern', type=>'text', default=>'CHM.PSCM.P.*' },
      { id=>'clean', label=>'Changeman Log Clean mode', type=>'text', default=>'RENAME' },
      { id=>'stateMap', label=>'Map states between Changeman and Baseliner', type=>'hash',
          default=>qq{{TEST=>'TEST', PREP=>'ANTE', FORM=>'PROD', ANTE=>'ANTE', CURS=>'CURS', ALFA=>'PROD', EXPL=>'PROD', PRUE=>'PROD', CINF=>'PROD', XXXX=>'PROD'}} },
      { id=>'frequency', label=>'Jes spool daemon frequency', type=>'text', default=>'15' },
      { id=>'iterations', label=>'Jes spool daemon iterations', type=>'text', default=>'1' },
      ]
};

sub run {
    my ( $self, $c, $config ) = @_;
    _log 'JES spool daemon starting.';

    my $frequency = $config->{frequency};
    my $iterations = $config->{iterations};
    my $bx = BaselinerX::Comm::Balix->new(os=>"unix", host=>$config->{host}, port=>$config->{port}, key=>$config->{key});

    for( 1..$iterations ) {
        $self->run_once( $c, $config, $bx );
        _log "******** End of Changeman file process loop ********";
        sleep $frequency;
    }
    _log 'JES spool daemon stopping.';
   1;
}

sub file_scan {
    my ( $self, $c, $config ) = @_;
    _log 'JES spool daemon starting.';
    $self->run_once( $c, $config );
    _log 'JES spool daemon stopping.';
   1;
}

sub creaPase {  ## $self->creaPase($c, $jobConfig, {package=>$pkg, date=>$date, type=>$type, user=>$user, bl=>$bl, key=>$key});
   my ($self, $c, $jobConfig, $p) = @_;
   my $package   = $p->{package};
   my $now       = $p->{date};
   my $type      = $p->{type};
   my $user      = $p->{user};
   my $bl        = $p->{bl};
   my $key       = $p->{key};
   my $runner    = undef;
   my $chmConfig = Baseliner->model('ConfigStore')->get( 'config.changeman.connection' );

   try {
       if( defined ( my $activeJob = Baseliner->model('Jobs')->is_in_active_job( "changeman.package/$package" ) ) ) {
           _debug _loc("Package <b>%1</b> is in active job <b>%2</b>", $package,$activeJob->id) if $activeJob;
           return $runner;
           # rgo: not sure if this is needed
           #my $oldjob = BaselinerX::Job::Service::Runner->new_from_id( jobid=>$activeJob->id, same_exec=>0, exec=>'last', silent=>1 );
           #$oldjob->logger->warn( _loc( "Job cancelled. There's more recent activity with Changeman package %1", $package ) );
           #Baseliner->model('Jobs')->cancel( id=>$activeJob->id );
       }

       $user||=$chmConfig->{user};
       BaselinerX::Changeman::Provider::Package->getPkg($c,{ query=>$package });
       my $nsid = "changeman.package/$package";
       my $pkg_data = Baseliner->model('Repository')->get( ns=>$nsid);
       if( ! ref $pkg_data ) {
           my $log_msg = _loc("Package <b>%1</b> does not exist in Changeman", $package);
           BaselinerX::ChangemanUtils->log( $log_msg );
           _throw $log_msg;
       }

       my $status = 'IN-EDIT';
       my $ahora = DateTime->now(time_zone=>_tz);
       my $end = $ahora->clone->add( years => 1 );

       my $job = Baseliner->model('Jobs')->create(
               starttime    => $now,
               schedtime    => $now,
               maxstarttime => $end,
               status       => $status,
               step         => 'PRE',
               type         => $type,
               runner       => $jobConfig->{runner},
               username     => $user || _loc('Unknown'),
               comments     => undef,
               ns           => '/',
               bl           => $bl,
               items        => [ $pkg_data ]
               );

       $job->stash_key( origin => 'changeman' );
       #$job->job_stash(_load bali_rs('Job')->find( $job->id )->stash);
       $job->status( 'READY' );
       $job->maxstarttime( $end );
       $job->update;

       #Baseliner->model('Baseliner::BaliRelationship')->update_or_create({type=>'changeman.id.to.job', from_ns=>$key, to_ns=>"job/".$job->id});
       $self->updateRelationship ($key, "job/".$job->id);

       $runner = BaselinerX::Job::Service::Runner->new_from_id( jobid=>$job->id, same_exec=>0, exec=>'last', silent=>1 );
       my $jobRow=bali_rs('Job')->search( {id=>$job->id} )->first;
       $runner->{job_row} = $jobRow;
       $runner->{job_data} = $jobRow->{_column_data};
   } catch {
       _log (_loc("Error: Can't create job: %1", $_));
       $runner = undef;
   };
   return $runner;
}

sub run_once {
   my ($self, $c, $config, $bx) = @_;
   my $workDir=$config->{workdir};
   my $jobConfig = Baseliner->model('ConfigStore')->get( 'config.job' );
   my $chmConfig = Baseliner->model('ConfigStore')->get( 'config.changeman.connection' );
   my $case = $c->config->{user_case};
   my $msg;
   my ($RC, $RET);
   my @files=();

   @files = BaselinerX::ChangemanUtils->spool_files( $bx, $config );
   $bx = $BaselinerX::ChangemanUtils::connection;

   my $user=undef;         ## Guarda el usuario creador del pase
   my $runner=undef;       ## Recoger el objeto pase de Baseliner
   my $row=undef;          ## Escribir en log
   my $type=undef;         ## Guarda el tipo de pase promote/demote
   my %finishedJOBS;       ## Iremos almacenando los jobs que van finalizando
   my @filestoclean;       ## Almacena los ficheros a limpiar al finalizar un pase

   foreach my $file (@files) {
      _log qq{PROCESS $file->{filename}};
      my ($fprefix) = $file->{filename} =~ m{^.*/(.*?)$};
      $fprefix = "[$fprefix] ";
      my $log_action = '';

      my $job=undef;       ## Almacena el job
      my $job_stash=undef; ## Almacena el job_stash
      my $jobID=undef;     ## Almacena jobID en Bali
      my $activeJob=undef; ## Recoge el ID del pase en Baseliner si existe
      my $logrow=undef;    ## Recoge linea de log para acceso a spool

      my ($key, $app, $pkg, $scm, $date, $site, $jobname, $filename)=($1, $2, "$2$3", $4, "$5-$6-$7 $8:$9", $10, $11, $_)
          if $file->{filename}->stringify =~ m{CHM\.PSCM\.P\.(\w+)\.(\w+)\..(\d+)\.(.)(\d{2})(\d{2})(\d+)\..(\d{2})(\d{2})\d+\.(\w+)\.(\S+)};
      my $pase=$date;
      $pase=tr{-:}{};

      my $bl=$chmConfig->{stateMap}->{$site};

      if ($file->{jobname} eq 'USERID') {
         if ($scm eq 'A') {
            my $pase="$1$2" if $file->{filename}->stringify =~ m{\.A(\d+)\.A(\d+)\.};
            # Baseliner->model('Baseliner::BaliRelationship')->update_or_create({type=>'changeman.id.to.job', from_ns=>$key, to_ns=>"job/".int($pase)}                                                                                       );
            $self->updateRelationship ($key, "job/".int($pase));
         } else {
            ($RC, $RET) = $bx->execute("cat ".$file->{filename}->stringify);
            $user = $1 if $RET =~ m{^(\w+).*};
            $user= $case eq 'uc' ? uc($user) : ( $case eq 'lc' ) ? lc($user) : $user;

            _debug $fprefix ."[USER] ". $user;
            #Baseliner->model('Baseliner::BaliRelationship')->update_or_create({type=>'changeman.id.to.job', from_ns=>$key, to_ns=>qq{user/$user}});
            $self->updateRelationship ( $key, qq{user/$user});
         }
         #push @filestoclean, $file->{filename}->stringify;
         $self->clean ($c, $bx, $config->{clean}, $file->{filename}->stringify);
         _debug $fprefix . "CLEANED";
         next; ## Es el fichero con el usuario que submite el job en CHM. No tiene mas proceso.
      }

      $type=undef;
      if ($file->{jobname}=~m{^....(1|2|3|8)...$} ) {
         $type=$type||='promote';
      } elsif ($file->{jobname}=~m{^....(4|5|6|7|9)...$} ) {
         $type=$type||='demote';
      }
      _debug $fprefix . "SOLVE TYPE: ".$file->{jobname}." ==> ". $type;

      $date = parse_date('yy-mm-dd',$scm ne 'A'?$date:_now);

      # Buscar pase activo con los datos del pase.
      my $ds=Baseliner->model('Baseliner::BaliRelationship')->search({type=>'changeman.id.to.job', from_ns=>$key})->first;
      if (ref $ds) {
         if ( $ds->to_ns =~ m{job/(\d+)} ) {
            $jobID=$1;  ## Ya esta procesado alguna vez y tiene pase asociado en SCM
            $job = bali_rs('Job')->find( $jobID ) if $jobID;
         } elsif ( $ds->to_ns =~ m{user/(\w+)} ) {
            $user=$1;   ## Ya esta procesado el fichero USERID
         }
      }

#      if ( ! defined $job && $scm eq 'A') {  ## No hay pase asociado en balirelationship, pero el pase viene de baseliner
#         my $activeJob = Baseliner->model('Jobs')->is_in_active_job( "changeman.package/$pkg" );
#         if (defined $activeJob ) {
#            $job=$activeJob if $activeJob->bl eq $bl && $activeJob->status eq 'WAITING' && $activeJob->type eq $type;
#            defined $job and $jobID=$job->id;
#         }
#      }

      if (ref $job) { ## Tengo creado el job en Baseliner, lo recupero
         $runner = BaselinerX::Job::Service::Runner->new_from_id( jobid=>$jobID, same_exec=>0, exec=>'last', silent=>1 );
         _debug $fprefix . "RELOAD JOB";
         my $jobRow=bali_rs('Job')->search( {id=>$jobID} )->first;
         $runner->{job_row} = $jobRow;
         $runner->{job_data} = $jobRow->{_column_data};
         $job_stash=_load $job->stash;
         $type=$job->type;
         if (($job->step eq 'RUN' && $job->status eq 'WAITING') || $job->step =~ m{POST|END} ) {
            $logrow  = bali_rs('Log')->find( $job_stash->{JESrow} );
            if (! $logrow) {
               $logrow=$runner->logger->info( _loc( "Recovered spool outputs for job <b>%1</b>", $runner->{job_data}->{name} ), more=>'jes' );
               $job->stash_key('JESrow',$logrow->id);
               $runner->job_stash(_load bali_rs('Job')->find( $runner->jobid )->stash);
            }
         }
      }

      _debug $fprefix . "TYPE: ".$file->{jobname} ." ==> ". $type;

      my $package = BaselinerX::Changeman::Provider::Package->get("changeman.package/$pkg"); ## Cargamos los datos del paquete CHM
      if ( $type eq 'promote' and $bl ne 'PROD' ) {
         _debug $fprefix . "PROMOTE";
         if ( ! defined $job ) { ## No está asociado aún a ningún pase, lo creamos.
            $runner=$self->creaPase($c, $jobConfig, {package=>$pkg, date=>$date, type=>$type, user=>$user, bl=>$bl, key=>$key});
            next if ! $runner;
            $row=$runner->logger->info( _loc( "User <b>%1</b> creates <b>PROMOTION</b> job for package <b>%2</b> to <b>%3</b> at <b>%4</b>", $user, $pkg, $bl, $date ) );
         } elsif ( $file->{jobname} =~ m{FIN(..)}i ) {  ## jobname de fin de promote OK or KO
            if ($job->step eq 'RUN' && $job->status eq 'WAITING') {
               if ( $1 eq 'OK' ) {
                  $row=$runner->logger->info( _loc( "Promotion for package <b>%1</b> to <b>%2</b> finished successfully", $pkg, $site ) );
               } else {
                  $row=$runner->logger->error( _loc( "Promotion for package <b>%1</b> to <b>%2</b> finished with error", $pkg, $site ) );
               }
               BaselinerX::Changeman::Service::deploy->finalize ({runner=>$runner, pkg=>$pkg, rc=>$1});
            }
         } else {
            _debug $fprefix . "JOB exists and not FIN - skipped";
         }
      } elsif ( $type eq 'demote' and $bl ne 'PROD' ) {
         _debug $fprefix . "DEMOTE";
         if ( ! defined $job ) { ## No está asociado aún a ningún pase, lo creamos.
            $runner=$self->creaPase($c, $jobConfig, {package=>$pkg, date=>$date, type=>$type, user=>$user, bl=>$bl, key=>$key});
            next if ! $runner;
            $row=$runner->logger->info( _loc( "User <b>%1</b> creates <b>DEMOTION</b> job for package <b>%2</b> to <b>%3</b> at <b>%4</b>", $user, $pkg, $bl, $date ) );
         } elsif ( $file->{jobname} =~ m{FIN(..)}i ) {  ## jobname de fin de demote OK or KO
            if ($job->step eq 'RUN' && $job->status eq 'WAITING') {
               if ( $1 eq 'OK' ) {
                  $row=$runner->logger->info( _loc( "Demotion for package <b>%1</b> to <b>%2</b> finished successfully", $pkg, $site ) );
               } else {
                  $row=$runner->logger->error( _loc( "Demotion for package <b>%1</b> to <b>%2</b> finished with error", $pkg, $site ) );
               }
               BaselinerX::Changeman::Service::deploy->finalize ({runner=>$runner, pkg=>$pkg, rc=>$1});
            }
         }
      } elsif ( $type eq 'promote' and $bl eq 'PROD' ) {
          _debug $fprefix . "INSTALL";
          if ( ! defined $job ) { ## No está asociado aún a ningún pase, lo creamos.
              $runner=$self->creaPase($c, $jobConfig, {package=>$pkg, date=>$date, type=>$type, user=>$user, bl=>$bl, key=>$key});
              if( ! $runner ) {
                  _debug $fprefix . "no RUNNER - skipped";
                  next;
              } else {
                  _debug $fprefix . "RUNNER OK: " . $runner->jobid;
              }
              $row=$runner->logger->info( _loc( "User <b>%1</b> creates <b>INSTALLATION</b> job for package <b>%2</b> to <b>%3</b> at <b>%4</b>", $user,$pkg, $bl, $date ) );
          } elsif ($job->step eq 'RUN' && $job->status eq 'WAITING') {
              if ( $file->{jobname} =~ m{....10..$} ) { ## DISTRIBUTED
                  _debug $fprefix . "DISTRIBUTED";
                  unless ($job->step eq 'RUN' && $job->status eq 'WAITING') {
                      _debug $fprefix . "not RUN and WAITING - skipped";
                      next;
                  }
                  $row=$runner->logger->info( _loc( "Package <b>%1</b> put into <b>%2</b> state in site <b>%3</b> finished successfully", $pkg, 'DISTRIBUTED', $site ) );
              } elsif ( $file->{jobname} =~ m{SITE(..)}i ) { ## INSTALLED
                  _debug $fprefix . "INSTALLED";
                  unless ($job->step eq 'RUN' && $job->status eq 'WAITING') {
                      _debug $fprefix . "JOB " . $job->id . " exists but not in RUN-WAITING - skipped";
                      next;
                  }
                  if ( $1 eq 'OK' ) {
                      $row=$runner->logger->info( _loc( "Package <b>%1</b> put into <b>%2</b> state in site <b>%3</b> finished successfully", $pkg, 'INSTALLED', $site ) );
                  } else {
                      $row=$runner->logger->error( _loc( "Package <b>%1</b> put into <b>%2</b> state in site <b>%3</b> finished with error", $pkg, 'INSTALLED', $site ) );
                  }
              } elsif ( $file->{jobname} =~ m{FIN(..)}i ) {  ## BASELINED
                  _debug $fprefix . "BASELINED";
                  if ( $1 eq 'OK' ) {
                      $row=$runner->logger->info( _loc( "Package <b>%1</b> put into <b>%2</b> state finished successfully", $pkg, 'BASELINED' ) );
                  } else {
                      $row=$runner->logger->error( _loc( "Package <b>%1</b> put into <b>%2</b> state finished with error", $pkg, 'BASELINED' ) );
                  }
                  BaselinerX::Changeman::Service::deploy->finalize ({runner=>$runner, pkg=>$pkg, rc=>$1});
              } else {
                  _debug $fprefix . "no match for WAITING, INSTALLED or DISTRIBUTED ";
              }
          } else {
              _debug $fprefix . "JOB " . $job->id . " exists but not in RUN-WAITING - skipped";
          }
      } elsif ( $type eq 'demote' and $bl eq 'PROD' ) {
          _debug $fprefix . "BACKOUT";
          if ( ! defined $job ) {
              $runner=$self->creaPase($c, $jobConfig, {package=>$pkg, date=>$date, type=>$type, user=>$user, bl=>$bl, key=>$key});
              next if ! $runner;
              $row=$runner->logger->info( _loc( "User <b>%1</b> creates <b>ROLLBACK</b> job for package <b>%2</b> to <b>%3</b> at <b>%4</b>", $user, $pkg, $bl, $date ) );
          } elsif ($job->step eq 'RUN' && $job->status eq 'WAITING') {
              _debug $fprefix . "WAITING";
              if ( $file->{jobname} =~ m{SITE(..)}i ) { ## NO HAY CAMBIO
                  next unless ($job->step eq 'RUN' && $job->status eq 'WAITING');
                  $row=$runner->logger->info( _loc( "Package <b>%1</b> put into <b>%2</b> state in site <b>%3</b> finished successfully", $pkg, 'BACKED OUT', $site ) );
              } elsif ( $file->{jobname} =~ m{FIN(..)}i ) {  ## BACKED OUT
                  _debug $fprefix . "FIN - BACKED OUT";
                  unless ($job->step eq 'RUN' && $job->status eq 'WAITING') {
                      _debug $fprefix . "not RUN and WAITING - skipped";
                      next;
                  }
                  if ( $1 eq 'OK' ) {
                      $row=$runner->logger->info( _loc( "Package <b>%1</b> has been <b>%2</b> successfully", $pkg, 'BACKED OUT' ) );
                  } else {
                      $row=$runner->logger->error( _loc( "Package <b>%1</b> has been <b>%2</b> with error", $pkg, 'BACKED OUT' ) );
                  }
                  BaselinerX::Changeman::Service::deploy->finalize ({runner=>$runner, pkg=>$pkg, rc=>$1});
              }
          }
      }

      next unless ref $runner;

      $job=bali_rs('Job')->find( $runner->{job_data}->{id});
      unless( $job->step =~ m{RUN|POST|END} && $logrow ) {
          _debug $fprefix . "step not in RUN,POST,END and logrow - skipped logging phase";
          next;
      }

      # logging of output
      if (( $file->{jobname} =~ m{FIN(..)|SITE(..)}i ) && $job->step !~ m{POST|END} ) {
          $log_action = "FIN-SITE - new dd for POST/END";
          _debug $fprefix . $log_action;
          #push @filestoclean, $file->{filename}->stringify;
          my $ddname="/$pkg/$site/$file->{jobname}";
          my $path="/$pkg/$site/ZZZ";
          my $logdata=$logrow->bali_log_datas->create({
                  id_log=>$logrow->id,
                  data=>$1,
                  name=>$ddname,
                  path=>$path,
                  type=>'jes',
                  len=>2,
                  id_job=>$jobID
                  });
          BaselinerX::ChangemanUtils->log( _loc('Daemon Processed. Action: %1',  $log_action ), filename=>$file->{filename}, job=>$file->{jobname}, scm=>$scm );
          $self->clean ($c, $bx, $config->{clean}, $file->{filename}->stringify);
          _debug $fprefix . "CLEANED";
      } else {
          $log_action =  "cat file output - jes split to log";
          _debug $fprefix . $log_action;
          #push @filestoclean, $file->{filename}->stringify;
          ($RC, my $text)=$bx->execute("cat ".$file->{filename}->stringify);
          ($RC, $text)=$bx->executeas($config->{user},"cat ".$file->{filename}->stringify) if $RC;
          my @RET=split / @==================== /, $text;
          foreach ( @RET ) {
              next if ! $_;
              my ($ddname, $spool)=split / ====================/, $_;
              $ddname=~s{\s*$}{};
              $ddname=~s{^\.}{};
              $ddname="/$pkg/$site/$file->{jobname}/$ddname";
              my $path="/$pkg/$site/$file->{jobname}";
              my $logdata=$logrow->bali_log_datas->create({
                      id_log=>$logrow->id,
                      data=>$spool,
                      name=>$ddname,
                      type=>'jes',
                      path=>$path,
                      len=>length($spool),
                      id_job=>$jobID
                      });
          }
          BaselinerX::ChangemanUtils->log( _loc('Daemon Processed. Action: %1',  $log_action ), filename=>$file->{filename}, job=>$file->{jobname}, scm=>$scm );
          $self->clean ($c, $bx, $config->{clean}, $file->{filename}->stringify);
          _debug $fprefix . "CLEANED";
      }

      if ( $file->{jobname} =~ m{FIN..}i ) {
          my $chm = BaselinerX::Changeman->new( host=>$chmConfig->{host}, port=>$chmConfig->{port}, key=>$chmConfig->{key} );
          my $ret;
          if ($scm eq 'A') { # Comes from Baseliner
              $ret= $chm->xml_cancelJob(job=>$runner->name, items=>[$pkg] ) ;
              if ($ret->{ReturnCode} ne '00') {
                  $log_action = _loc( "Package %1 can not be dessassociatted from job %2", $pkg, $runner->name );
                  $row=$runner->logger->warn( $log_action, _dump $ret );
              } else {
                  $log_action = _loc( "Package %1 dessassociatted from job %2", $pkg, $runner->name );
                  $row=$runner->logger->debug( $log_action, _dump $ret );
              }
          } else { # Comes from Changeman. CHM Package is not associated to a SCM job
              $log_action = "FIN but not A - ignored";
              _debug $fprefix . $log_action; 
          }
          BaselinerX::ChangemanUtils->log( _loc('FIN from Daemon. Job: %1. Return Code: %2. Action: %3', $runner->name, $ret->{ReturnCode}, $log_action ),
              filename=>$file->{filename}, job=>$file->{jobname}, scm=>$scm );
      } else {
          $log_action = "jobname not FIN - ignored";
          _debug $fprefix . $log_action; 
      }
   }
   #$self->clean ($c, $bx, $config->{clean}, @filestoclean);
   return 1;
}

sub clean {
    my ($self, $c, $bx, $clean, @filenames) = @_;
    foreach my $file (@filenames) {
        $file=_loc_ansi($file);            
        my ($RC, $RET);
        if ($clean eq 'RENAME') {
            my $newfile = $file;
            $newfile =~ s{\.P\.}{\.T\.};
            _debug $file . "CLEAN " . qq{mv $file $newfile};
            ($RC, $RET)=$bx->execute (qq{mv "$file" "$newfile"});
            ($RC, $RET)=$bx->executeas($config->{user},qq{mv "$file" "$newfile"}) if $RC;
        } elsif ($clean eq 'DELETE') {
            ($RC, $RET)=$bx->execute(qq{rm "$file"});
            ($RC, $RET)=$bx->executeas($config->{user},qq{rm "$file"}) if $RC;
        }
        _debug $file . "CLEAN" . $RET; 
    }
    return;
}

sub updateRelationship {
my ($self, $from_ns, $to_ns) = @_;

my $ds=Baseliner->model('Baseliner::BaliRelationship')->search({type=>'changeman.id.to.job', from_ns=>$from_ns})->first;
if (ref $ds) {
   $ds->to_ns($to_ns) unless $ds->to_ns =~ m{job/\d+};
   $ds->update();
   _debug "RELATIONSHIP FROM ". $from_ns . " TO ". $ds->to_ns;
} else {
   Baseliner->model('Baseliner::BaliRelationship')->update_or_create({type=>'changeman.id.to.job', from_ns=>$from_ns, to_ns=>$to_ns});
   _debug "RELATIONSHIP FROM ". $from_ns . " TO ". $to_ns;
}
}

1;
