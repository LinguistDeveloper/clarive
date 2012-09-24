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
            my ($key, $app, $pkg, $scm, $date, $bl, $jobname, $filename)=($1, $2, "$2$3", $4, "$5-$6-$7 $8:$9", $10, $11, $_) if $_ =~ m{CHM\.PSCM\.P\.(\w+)\.(\w+)\..(\d+)\.(.)(\d{2})(\d{2})(\d+)\..(\d{2})(\d{2})\d+\.(\w+)\.(\S+)};
            if ( $app ) {
               $jobname=~s{\xD1}{#};
               my $ord=$jobname=~m{USERID$}?0:$jobname=~m{SITEOK$}?2:$jobname=~m{FINOK$}?3:1;
               +{
                  ord=>"$key.$ord.$jobname",
                  date=>$date,
                  mdate=> $mdates{ $filename },
                  app=>$app,
                  bl=>$bl,
                  filename=>_file('/tmp/CHMT',$filename),
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
1;
