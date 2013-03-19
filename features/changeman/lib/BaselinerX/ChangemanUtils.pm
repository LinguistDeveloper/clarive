package BaselinerX::ChangemanUtils;
use Moose;
use Try::Tiny;
use Baseliner::Utils;
use Class::Date;

our $connection;

# connect or use current connection
sub connect_to_spool {
   my ($self, $bx, $config) = @_;
   $config //= Baseliner->model('ConfigStore')->get( 'config.changeman.log_connection' );
   $bx //= $connection;
   try { ## Comprobamos que la conexion balix continue abierta
      local $SIG{ALRM} = sub { die "alarm\n" };
      alarm 60;
      my ($RC, $RET)=$bx->execute(qq{whoami});
      alarm 0;
   } catch {
      my $err = shift;
      $err =~ /alarm/ and  _log "$config->{host} connection timeout";   # maybe we just dont have a $bx
      $bx = BaselinerX::Comm::Balix->new(os=>"unix", host=>$config->{host}, port=>$config->{port}, key=>$config->{key});
      my ($RC, $RET)=$bx->execute(qq{whoami});
      die "Could not connect to $config->{host}. Exiting" if ( $RC ne 0 );
   };
   $connection = $bx;
   return ($bx,$config);
}

# list spool files
sub spool_files {
   my ($self, $bx, $config) = @_;

   my $jobConfig = Baseliner->model('ConfigStore')->get( 'config.job' );
   my $chmConfig = Baseliner->model('ConfigStore')->get( 'config.changeman.connection' );
   my $msg;
   my ($RC, $RET);
   my @files=();

   $config //= Baseliner->model('ConfigStore')->get( 'config.changeman.log_connection' );
   ($bx,$config) = $self->connect_to_spool( $bx, $config );
   my $workDir=$config->{workdir};

   ($RC, $RET)=$bx->execute(qq{cd $config->{logPath}; ls -tr $config->{pattern}}); ## recuperamos los ficheos de spool

   unless ( $RC ){
       # now get the file stats (this is better than using -la)
       my ($RC2, $RET2)=$bx->execute(qq{ls $config->{logPath}/* | perl -n -l -e 'print \$_ . "," . [stat \$_]->[9]' }); ## last modify time
       my @fstats = split /\n/, $RET2;
       # build a hash 
       my %mdates = map {
           my ($fn, $mdate)=split /,/;
           my $bn = _file( $fn )->basename;
           $bn => Class::Date::date($mdate);
       } @fstats;
       @files = sort {$a->{ord} cmp $b->{ord}} (
         map {
            # PATTERN : CHM.PSCM.P.10WPIGXAFVKV.SCTT.N000161.F120704.H134924.CINF.SCT#3061
            # PATTERN : CHM.PSCM.P.1DIHKV3G888B.SCTT.N000166.A00000.A02362.PREP.SCT#8266

            my ($key, $app, $pkg, $scm, $date, $bl, $jobname, $trash, $filename)=($1, $2, sprintf("%-4s%s",$2,$3), $4, "$5-$6-$7 $8:$9", $10, $11, $12, $_) 
               if $_ =~ m{CHM\.PSCM\.P\.(\w+)\.(\w+)\..(\d+)\.(.)(\d{2})(\d{2})(\d+)\..(\d{2})(\d{2})\d+\.(\w+)\.(\S+?)(\..*)};
            $key=~s{REVERT}{ZZZREVERT}g;

            if ( $app ) {
               $jobname=~s{\xD1}{#};
               my $ord=$jobname=~m{USERID$}?0:$jobname=~m{SITEOK$}?2:$jobname=~m{FINOK$}?3:1;
               +{
                  ord=>"$key.$ord.$jobname",
                  date=>$date,
                  mdate=> $mdates{ $filename },
                  app=>$app,
                  bl=>$bl,
                  filename=>_file($config->{logPath} ,$filename),
                  jobname=>$jobname
               };
            }
         } split /\n/,$RET
      );
   }
   return @files;
}


# get a remote spool file
sub file_retrieve {
   my ($self, $bx, $config, @file_basenames ) = @_ ;

   ($bx,$config) = $self->connect_to_spool( $bx, $config );
   my $path=$config->{logPath};

   my @files;

   for my $f ( @file_basenames ) {
       my $fansi = $f = "" . _file( $path, $f );   # put the path
       Encode::from_to( $fansi, 'utf8', 'iso-8859-1' );
       my ($RC, $RET)=$bx->execute(qq{cat $fansi});
       _fail _loc( 'Error retrieving file %1: %2', $f, $RET)  if $RC > 0;
       push @files, $RET;
   }
   return wantarray ? @files : $files[0];
}

# delete a spool file
sub file_delete {
   my ($self, $bx, $config, @file_basenames ) = @_ ;

   ($bx,$config) = $self->connect_to_spool( $bx, $config );
   my $path=$config->{logPath};

   my @files;

   for my $f ( @file_basenames ) {
       my $fansi = $f = "" . _file( $path, $f );   # put the path
       Encode::from_to( $fansi, 'utf8', 'iso-8859-1' );
       my ($RC, $RET)=$bx->execute(qq{rm $fansi});
       _fail _loc( 'Error retrieving file %1: %2', $f, $RET)  if $RC > 0;
       push @files, $RET;
   }
   return wantarray ? @files : $files[0];
}

sub log_purge {
    my $keep_rows = 50; 
    my $repo = Baseliner->model('Baseliner::BaliRepo')->search({ provider=>'changeman.logger' });
    my $keep = $repo->search(undef,{ rows=>$keep_rows, select=>'ns', order_by=>{ -desc=>'ts' } })->as_query;
    $repo->search({ -not=>{ ns=>{ -in=>$keep } } })->delete();
}

# log a set of parameters
sub log {
    my ($self, $msg, %args ) = @_;
    
    my ($cl,$fi,$li) = caller;
    $self->log_purge;

    # TODO make this an event
    try {
        Baseliner->model('Repository')->set(
            domain=>"changeman.logger",
            ns=> "changeman.log.entry/" . _nowstamp(),
            data=>{ msg=>$msg, 
                class => $cl, file=>$fi, line=>$li,            
                logdate=>""._now(), %args }
        );
    } catch {
        _error "Logger error: " . shift();
    };
}

use Baseliner::Sugar;

event_hook 'event.job.new' => 'after' => sub {
    my $ev = shift;
    my ($self,$c, $job, $job_data ) = @{ $ev->data }{qw/self c job job_data/};
    my $p = $c->req->params;

    my $items = $job_data->{items};
    my $job_name = $job->name;

    # Linked list to job-options in the stash
    my $ll = $p->{check_linked_list} eq 'on' ? 1 : 0;
    $job->stash_key( chm_linked_list => $ll );

    #Procesamos items de Changeman
    if ($p->{job_contents} =~ m{namespace.changeman.package}g) {
        my $cfgChangeman = Baseliner->model('ConfigStore')->get('config.changeman.connection' );
        my $chm = BaselinerX::Changeman->new( host=>$cfgChangeman->{host}, port=>$cfgChangeman->{port} );
        my $ret= $chm->xml_addToJob(job=>$job_name, items=>$items ) ;
        if ($ret->{ReturnCode} ne '00') {
            $job->delete;
            _fail( _loc( "Error creating Changeman Job:<br>%1",$ret->{Message}) );
        } else {
            ##TODO: Si requiere aprobacion de host por refresco de linklist crear la aprobacion
            # $job->bali_job_items->create({item => 'nature/zos'}); 
            my $log = new BaselinerX::Job::Log({ jobid=>$job->id });
            $log->debug(_loc("Changeman package(s) has been associated to SCM job %1", $job_name ));
        }
    }
};

event_hook [qw/event.job.cancel event.job.cancel_running/] => 'after' => sub {
    my $ev = shift;
    my ($self,$c, $job ) = @{ $ev->data }{qw/self c job /};
    # $c is not available if it comes from Model::Jobs

    my $username = try { $c->username } catch { 'internal' };
    my $job_name = $job->name;

    # CANCELAR JOB EN CHANGEMAN SI PROCEDE
    my $cfgChangeman = Baseliner->model('ConfigStore')->get('config.changeman.connection' );
    my $chm = BaselinerX::Changeman->new( host=>$cfgChangeman->{host}, port=>$cfgChangeman->{port}, key=>$cfgChangeman->{key} );
    my $rs_items = Baseliner->model('Baseliner::BaliJobItems')->search({ id_job=>$job->id, provider =>'namespace.changeman.package' } );
    rs_hashref($rs_items);
    my @pkgs;
    while (my $row=$rs_items->next) {
        my $name=$1 if $row->{item} =~ m{changeman.package/(.*)};
        push @pkgs, $name if $name;
    }

    if (scalar @pkgs) { 
        my $ret= $chm->xml_cancelJob(job=>$job->name, items=>\@pkgs) ;
        if ($ret->{ReturnCode} ne '00') {
            my $msg = _loc("Job %1 cancelled", $job_name);
            if( $c ) {
                $c->stash->{json} = { success => \1, msg =>$msg  };
            } else {
                _log $msg;
            }
        } else {
            my $msg = _loc("Job %1 cancelled<br>Changeman package(s) desassociated)", $job_name);
            if( $c ) {
                $c->stash->{json} = { success => \1, msg => $msg  };
            } else {
                _throw $msg; 
            }
        }
        $job->update;
        ## Al cancelar el job, quitamos las relaciones de BaliRelationship
        my $relation=Baseliner->model('Baseliner::BaliRelationship')->search({type=>'Changeman.PDS.to.JobId', to_ns=>"job/".$job->id});
        ref $relation && $relation->delete;

        my $log = new BaselinerX::Job::Log({ jobid=>$job->id });
        $log->error(_loc("Job cancelled by user %1", $username));
    } else {
        $job->update;
        my $log = new BaselinerX::Job::Log({ jobid=>$job->id });
        $log->error(_loc("Job cancelled by user %1", $username));
    }
};

1;
