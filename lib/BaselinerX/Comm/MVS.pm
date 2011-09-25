package BaselinerX::Comm::MVS;
use strict;
use Baseliner::Utils;
use File::Path;
use Try::Tiny;

use MVS::JESFTP;
use Carp;
#use Error qw(:try);

## inheritance
use vars qw($VERSION);
$VERSION = '1.0';

sub opt { $_[0]->{opts}->{$_[1]} }
sub opts { $_[0]->{opts} }

sub new {
	my $class = shift();
	my %opts = @_;
	my %jobs=();
	
	$opts{timeout} ||= 20;
	my $temp = $ENV{BASELINER_TEMP} || $ENV{TEMP};
	$opts{tempdir} ||=  $temp ? "$temp/mvsjobs" : "./mvsjobs"  ;
	
	my $self = {
		opts=> \%opts,
		jobcount => 0,
		jes => '',
		jobs => \%jobs,
        %opts,
	};
	bless( $self, $class);
}

sub open {
	my $self=shift;
	if( ! ref $self ) {
		$self = __PACKAGE__->new( @_ );
	}
	$self->{jes} = MVS::JESFTP->open($self->opts->{'host'}, $self->opts->{'user'}, $self->opts->{'pw'}) 
		or confess _loc("Could not logon to host %1, user: %2: %3", $self->opts->{'host'}, $self->opts->{'user'}, $! );

	mkpath $self->opt('tempdir')
		if( ! -d $self->opt('tempdir') );
	confess _loc("Could not find a temporary job directory '%1'", $self->opt('tempdir') ) 
		if( ! -d $self->opt('tempdir') );
	return $self if defined wantarray;
}

sub reopen {
	my $self=shift;
	$self or _throw 'reopen failed: self not defined';

	# close
	try {
		$self->{jes}->quit if $self->{jes};
	};

	# open
	$self->{jes} = MVS::JESFTP->open($self->opts->{'host'}, $self->opts->{'user'}, $self->opts->{'pw'}) 
		or confess _loc("Reopen: Could not logon to host %1, user: %2: %3", $self->opts->{'host'}, $self->opts->{'user'}, $! );
}

sub loginfo {
	my $self=shift;
    my $logger = $self->{opts}->{logger} || $self->{logger};
    if( defined $logger ) {
        $logger->info( @_ );
    } else {
        warn @_;
    }
}

sub submit {
	my $self=shift;
	my @jobs;
	while ( my $jobtxt = shift @_ ) {
		my $tempdir = $self->opt('tempdir');
		# my $jobfile = $tempdir."/pkg".sprintf('%05d',$self->{jobcount}++).".$$.jcl";
		my $jobfile = $tempdir."/pk".sprintf('%06d',$$).".jcl";
		my ($jobname, $letter, $letter_next) = $self->_gen_jobname_global(); 
		warn "MVS Submitted JOBNAME=$jobname";
		if( ! $self->opt('keep_name') ) {
			$jobtxt =~ s{^//[A-Z]*}{//$jobname}s;  ## replace job code with generated job code
			$jobtxt =~ s{\$\{LETTER\}}{$letter}s;
			$jobtxt =~ s{\$\{LETTER_NEXT\}}{$letter_next}s;
			$jobtxt =~ s{\$\{JOBNAME\}}{$jobname}s;
		} 
		
		##else {
		##	( $jobname = $jobtxt ) = ~ s{^(//[A-Z]*).*$}{$1}; ## extract the job name from the job code
		##}
		
		CORE::open JF, ">$jobfile";
		print JF $jobtxt;
		close JF;
		$self->{jes}->submit($jobfile) || confess _loc("Could not submit job '%1': %2", $jobname, $!);
		unlink $jobfile;
			
		my $msg = $self->{jes}->message;
		my $JobNumber = $self->_jobnumber($msg);
		$self->{jobs}{$JobNumber}{status} = 'Submitted';
		$self->{jobs}{$JobNumber}{name} = $jobname;
		$self->{jobs}{$JobNumber}{job} = $jobtxt;
		push @jobs, $JobNumber;
		warn "MVS Submitted $JobNumber";
		$self->loginfo( "MVS Submitted $jobname $JobNumber" );
	}
	
	return wantarray ? @jobs : shift @jobs;
}

sub name {
	my $self = shift;
	my $jobid = shift;
	return $self->{jobs}{$jobid}{name};
}

sub jobtxt {
	my $self = shift;
	my $jobid = shift;
	return $self->{jobs}{$jobid}{job};
}

sub do {
	my $self = shift;
	my $jobid = $self->submit( shift );
    
	my $output = $self->wait_for( $jobid );

    return $output;
}

sub wait_for_all {
	my ($self, %p) = @_;

    my @ret;

    #FIXME apparently at some levels, the output may be empty if following a wrong lead
    #_throw _loc("Missing output") unless $p{output}; 
    _log("Missing output"), return unless $p{output};

    # find underlying jobs
    for my $job ( $self->more_jobs( output=>$p{output} ) ) {
        _log _loc( "Esperando subjob %1 para el usuario %2 (parent=%3, level=%4)...", $job->{id}, $job->{user}, $job->{parent_id}, $p{level} );

        _throw "Invalid JobID" unless $job->{id};

        # wait for subjob
        $job->{output} = $self->wait_for( $job->{id} );
		$job->{level} = $p{level} || 1;
		_log _loc('Ok. Got output for job %1.', $job->{id} ) if $job->{output};
        push @ret, $job;

		# notify callback
		if( ref $p{callback} eq 'CODE' ) {
			my $cb = $p{callback};
			$cb->(output=>$job->{output}, id=>$job->{id}, level=>$p{level} );
		}

        # now recurse...
        push @ret, grep { defined } $self->wait_for_all( output=>$job->{output}, level=>$p{level}+1 );
    }
    return @ret;
}

sub do_recurse {
	my ($self, $jcl, $callback)=@_;

    my @result;

	my $jobid = $self->submit( $jcl );
	my $output = $self->wait_for( $jobid );

    push @result, { id=>$jobid, output=>$output, level=>0 };
	if( ref $callback eq 'CODE' ) {
		$callback->(output=>$output, id=>$jobid, level=>0 );
	}
    push @result, $self->wait_for_all( output=>$output, callback=>$callback, level=>1 );
    return @result;
}

sub wait {
	my $self=shift;

WW:	while( $self->pending ) {
		for ( $self->finished_jobs ) {
			my $num = $self->_jobnumber( $_ );
			$self->{jobs}{$num}{status}='Finished';			
		}
	}
}

sub pending {
	my $self=shift;
	my @ret;
	for( $self->jobs ){
		push @ret, $_ if $self->{jobs}{$_}{status} eq 'Submitted';
	} 
	return @ret; 
}

# generic
sub wait_for {
    my ($self, $JobNumber) = @_;
    my $from = $self->{wait_for} || 'get';
    my $method = "wait_for_$from";
    return $self->$method( $JobNumber );
}

sub wait_for_dir {
	my $self=shift;
	my $JobNumber = shift;

WW:	while( 1 ) {
		for ( $self->finished_jobs ) {
			my $num = $self->_jobnumber( $_ );
			$self->{jobs}{$num}{status}='Finished';
			last WW if $num eq $JobNumber;   			
		}
	}
	return $self->output( $JobNumber);
}

sub touch {
    my ($self, $file ) = @_;
    CORE::open my $ff,'>', $file or return;
    close $ff;
    return 1;
}

sub wait_for_get {
    my ($self, $jobnum) = @_;
	my $jes = $self->{jes};
    
    my $freq_orig = $self->opt('get_frequency') || 10;
    my $freq = $freq_orig;
	my $dir = $self->opt('tempdir');
    # file names
    my $file_tmp = $dir . '/' . $jobnum . '.tmp';
    my $file_manual = $dir . '/' . $jobnum . '.manual'; # interrupts wait
    my $file_final = $dir . '/' . $jobnum . '.out';
    my $file_req = $dir . '/' . $jobnum . '.request'; # notifies whoever that I'm waiting for something

    $self->touch( $file_req );

    # Fast JES LIST loop
    while( 1 ) {
        last if grep /$jobnum/, $jes->ls; # ok, its in JES
        last if -s $file_manual; # ok, its fake, I'm out
        sleep $freq;
        $freq++ if $freq < 30;
    }
    $freq = $freq_orig; # reset frequency

    # GET loop - attempts to get until it has some data in it
    my ($last_size, $attempts)=(0,0);
    while( 1 ) {
        # ok, found something (real or fake)
        my $rc_get = 0;
        unless( -s $file_manual ) {
            sleep 5; # give time to wait for job
            $rc_get = $jes->get( $jobnum, $file_tmp );
        }
        if( $rc_get && -s $file_tmp ) {
            # we have data, check for suspicious size
            my $filesize = [stat $file_tmp]->[7]; 
            if( $filesize < 6000 && $attempts++ < 3 ) {
                $last_size = $filesize;
                next;
            }
            # check for J E S content
            if( $attempts++ < 3 ) {
                $rc_get = $jes->get( $jobnum, $file_tmp );
                my $output = $self->_slurp( $file_tmp );
                next unless $output !~ m/J E S/sg;
            }
            #XXX check for stable size 
            # ok, it's good
            rename $file_tmp, $file_final;
            last;
        }
        elsif( -s $file_manual ) {
            unlink $file_tmp;
            rename $file_manual, $file_final;
            last;
        }
        else {
            unlink $file_tmp;
        }
        sleep $freq;
        $freq++ if $freq < 30;
    }

    unlink $file_req;
    my $output = $self->_slurp( $file_final );
    return $output;
}

sub _slurp {
    my ( $self, $file ) = @_;
    CORE::open my $fin, '<', $file
        or die "Could not open file '$file': $!";
    my $output = join'',<$fin>;
    close $fin;
    return $output;
}

sub more_jobs {
    my ( $self, %p ) = @_;

	my $d = $p{output} ? $p{output} : $self->output( $p{job_number} );
    my %jobs;

    for my $jobline ( $d =~ /JOB[0-9]{5}.*?\n/gs ) {
        chomp $jobline;
        if( $jobline =~ m/(JOB[0-9]{5}).*USERID.(\w+)/ ) {
            my $job = $1;
            my $uid = $2;
            $jobs{$job}{user}= $uid;
        }
        if( $jobline =~ /(JOB[0-9]{5}).*\.HASP100 (\S+).+FROM (JOB[0-9]+) (\S+)/ ) {
            my $job = $1;
            my $name = $2;
            my $parent_id = $3;
            my $parent_name = $4;
            $jobs{$job}{name}= $name;
            $jobs{$job}{parent_id}= $parent_id;
            $jobs{$job}{parent_name}= $parent_name;
        }
    }

    return map { { id=>$_, user=>$jobs{$_}{user}, name=>$jobs{$_}{name} } } grep { exists $jobs{$_}{name} } keys %jobs;
}

sub output {
	my $self=shift;
	my $JobNumber = shift;
	my $tmpdir = $self->opt('tempdir');
	my $output;
	try { File::Path::mkpath( $tmpdir ) }
		catch { _throw _loc("Could not create path '%1': %2", $tmpdir, shift ) };
	my $jobout = $self->opt('tempdir')."/$JobNumber.out";
	my $JESConfig = Baseliner->model('ConfigStore')->get( 'config.JES', ns=>'/', bl=>'*' );
	use Data::Dumper; 
	
	for( 1..$JESConfig->{attempts} ) {  # 3 attempts to get it
		_log _loc "Attempt %1 to get job %2 output", $_, $JobNumber;
		my $JESOUT=$self->{jes}->get($JobNumber,$jobout);

		try {
			CORE::open JO,"<$jobout" ; ## or _throw( _loc("Could not open file %1: %2", $@) );
			$output.= $_ for <JO>;
			close JO;
		} catch {
			_log _loc("Could not open file %1: %2", $@);
		};

		last if $output;
		# reopen ftp jes connection
		# $self->reopen;
		sleep $JESConfig->{interval};
	}

	# unlink $jobout;
	
	_log _loc("Unable to retrieve the output for Job %1. Check QE>Q>1>H (Display Promotion History) to see the result", $JobNumber ) unless $output;
	$self->{jes}->delete($JobNumber) unless( $ENV{MVS_NOPURGE} );;
	return $output;	
}

=head2 codepage( from_codepage, to_codepage )

Changes the data codepage:

   $mvs->codepage('IBM-1145', 'IBM-1252' )

=cut
sub codepage {
	my ($self, $from, $to ) = @_;
    die 'Missing parameter from' unless $from;
    die 'Missing parameter to' unless $to;
	$self->{jes}->quot('SITE', "SBD=($from,$to)" );
}

sub close {
	my $self=shift;
	rmdir $self->opt('tempdir');
	return unless ref $self->{jes};				
	for( $self->jobs ) {
		$self->{jes}->delete( $_ ) unless( $ENV{MVS_NOPURGE} );
	}
	$self->{jes}->quit();
}

sub jobs {
	my $self=shift;
	return keys %{$self->{jobs}};	
}

sub submitFile {
	my $self=shift;
	##TODO
}

sub queue {
   my ($self) = @_; 
   return $self->{jes}->dir;
}

sub finished_jobs
{
	my $self=shift;
	my $JES = $self->{jes};
	my $i = 0;
	my @Dir = "";

	while (++$i <= $self->opt('timeout') )			# Espera el tiempo especificado en TIMEOUT
	{
		last if (@Dir = grep /OUTPUT/,$JES->dir); # Solo los JOBS en OUTPUT
		sleep(1);
	}
	return @Dir;					# Devuelve lista de JOBs en OUTPUT
}

sub _jobnumber
{
	my $self=shift;
	my $Message = shift @_;
	return substr($Message,index($Message,"JOB"),8);			# Search and return the job number
}

sub _queuesize {
	my $self=shift;
	my $k=0;
	for( keys %{$self->{jobs} } ) {
		$k++ if $self->{jobs}{$_}{status} eq 'Submitted';
	}
	return $k;
}

use Data::Random qw(rand_chars);
sub _genjobname_random {
	my $self=shift;
	my $user = substr( $self->opt('user') , 0, 3 );
    my $id = join '', rand_chars( set => 'alphanumeric', min => 5, max => 5 );
    return uc( $user . $id );
}

sub _genjobname {
	my $self=shift;
	my $user = uc($self->opt('user'));
	my $id = $self->_queuesize;
	$id = $id % 25;
	return ($user.chr(65 + $id) );
}

#my $valid_letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
my $valid_letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
sub _gen_jobname_global {

	my $self=shift;
	my $user = uc($self->opt('user'));
	my $id;
	my $id_next; # the next id, just in case somebody needs it
	## Para evitar accesos concurrentes al mismo registro... Pases a la misma hora generan identico JOBNAME
	Baseliner->model('Baseliner')->txn_do ( sub {
		my $queue_size = $self->_queuesize;
		my $global_size = try { Baseliner->model('Repository')->get( provider=>'mvs.queue', ns=>'queuesize' ) } catch { 0 };
		my $total_size = $queue_size + $global_size + 1 ;
		Baseliner->model('Repository')->set( provider=>'mvs.queue', ns=>'queuesize', data=>$total_size );
		$id = $total_size % length($valid_letters);
		$id_next = ($total_size + 1) % length($valid_letters);
	});

	my $letter = substr($valid_letters, $id, 1);
	my $letter_next = substr($valid_letters, $id_next, 1);
	return ( $user . $letter, $letter, $letter_next );
}

sub parse_code {
	
    my $self    = shift;
    my $output  = shift;
    my $jobname = shift;

    my $MaxReturnCode;
    my $MaxStep;
    my $ReturnCode;
    my $linea;
    my $Step;


    my @logFile = split '\n', $output;

    if ( grep /JOB NOT RUN - JCL ERROR/, @logFile ) {
        $MaxReturnCode = "99999";
    } else {

#@Summary = grep /- STEP WAS EXECUTED - COND CODE/, @LogFile; # Lineas de resumen
#eval '@Summary = grep /'. $JobNumber.'\s+GSDMV21I\s+.*'. $JobName.'\s+.{1,8}\s+.{1,8}\s+.*/, @LogFile';
        my @Summary = grep /- STEP WAS EXECUTED - COND CODE/, @logFile;
        _log "Lineas:".@Summary;
        foreach my $linea ( @Summary ) {
            my $exp = "";

            eval '$exp = qr/^.*\s+(.*)\s+- STEP WAS EXECUTED - COND CODE\s(.*)$/';

            #eval '$exp = qr/.*' . $JobName . '\s{1,2}(.{8})\s+(.{1,8})\s+(.{1,5})\s+\.*/';

            $linea =~ $exp;
            $Step = $1;
            $ReturnCode = $2;
            $Step =~ s/\s//g;
            $ReturnCode =~ s/\s//g;
            _log "RET: $ReturnCode, Step: $Step";
            # Actualiza el CR y STEP máximo del JOB si no FLUSH
            if ( $ReturnCode gt $MaxReturnCode ) {
                $MaxReturnCode = $ReturnCode unless $ReturnCode eq "FLUSH";
                $MaxStep       = $Step       unless $ReturnCode eq "FLUSH";
            }
        }
    }
    _log "Max: $MaxReturnCode, Step: $MaxStep";
    return ($MaxReturnCode, $MaxStep);
}

DESTROY {
	my $self=shift;
	$self->close();
}

=head1 SYNOPSIS
Submits jobs thru the JES queue using MVS::JESFTP;

	my $mvs = Baseliner::Comm::MVS->open( host=>'mybigcpu', user=>'myuser', pw=>'mypassword' );
	my $job = $mvs->submit( $jobtxt1 );
	## submit more here if you want
	$mvs->wait();  ## wait till all submitted jobs are thru
	my $output = $mvs->output($job);
	
Or you can submit a few at once:

	my $mvs = Baseliner::Comm::MVS->open( host=>'mybigcpu', user=>'myuser', pw=>'mypassword' );
	my ($job1,$job2,$job3...) = $mvs->submit( $jobtxt1,$jobtxt2,$jobtxt3... );
	$mvs->wait();
	my $output = $mvs->output($job);	
	
Or just quick-and-dirty:

	my $mvs = Baseliner::Comm::MVS->open( host=>'mybigcpu', user=>'myuser', pw=>'mypassword' );
	my $output = $mvs->do( <<JOBEND );  ## will wait for it to end and return its output
//jobnameA ....		

=cut 

1;
